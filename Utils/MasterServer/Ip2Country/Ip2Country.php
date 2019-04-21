<?php
/**
 * This class contains the capability to look up IP addresses and return the correct
 * country, based on the lookup data generated from process_csv.php.
 *
 * Since PHP cannot handle 32-bit unsigned longs, we translate the IP addresses
 * into 4-byte strings instead, which also should safeguard against future IPv6
 * lookups.
 *
 * The index file contains 12-byte records, grouped into three 32-bit dwords.
 * The first is an IP block address, the second contains the position in the data
 * file, and the third is the block length for that IP group.
 *
 * The data file contains a long list of 6-byte records, the first four form the
 * start of the IP address block and the remaining two bytes the two-letter ISO
 * country code to which that IP block is allocated.
 *
 * The lookups are done by calculating the "group number" of the IP address,
 * which is the high 13 bits, and looking that up in a hash table. This yields
 * a position into the data file, which can be either preloaded or loaded on
 * demand. The data is then searched using a binary tree search, yielding
 * effectively O(log2 n) lookups.
 *
 * Memory is used very conservatively - since we only use strings to represent
 * data, a fully preloaded database should add about 1.2 MB of internal memory.
 *
 * On a 2.3 GHz Intel Core i5 we get about 40,000 lookups per second.
 */
class Ip2Country
{
    private $index = null;     // Holds the preloaded index
    private $data  = [];  // Holds the data records, one chunk per index group
    private $fp;
    private $offset;
    private $datalen;
    private $lastentry;
    private $fullNames;

    /**
     * Initializes the ip to country lookup tables and preloads the index.
     */
    public function __construct($datafile = null)
    {
        if (!$datafile) {
            $datafile = __DIR__ . '/data/ip2country.dat';
        }

        $this->fp = fopen($datafile, 'r');
        $this->fullNames = json_decode(file_get_contents(__DIR__ . '/data/names.json'), true);

        $header = fread($this->fp, 8);
        list(, $indexlen, $this->datalen) = unpack('L2', $header);
        $this->offset = 8 + $indexlen;

        $this->index = array_fill_keys(range(0, 8191), null);
        $index = str_split(fread($this->fp, $indexlen), 12);

        foreach ($index as $ix) {
            $this->index[self::ipgroup($ix)] .= $ix;
        }

        $lastv = null;

        foreach ($this->index as $k => &$v) {
            if ($v) {
                $lastv = $v;
            } else {
                $v = $lastv;
            }
        }
    }

    /**
     * Destroys the ip 2 country instance.
     */
    public function __destruct()
    {
        if ($this->fp) {
            fclose($this->fp);
        }
    }

    /**
     * Get the group of an IP address by returning the 13 high bits
     */
    public static function ipgroup($ipbin)
    {
        return (ord($ipbin[0]) << 8 | ord($ipbin[1])) >> 3;
    }

    /**
     * Preloads the entire data file into memory for faster lookups of many IP
     * addresses
     */
    public function preload()
    {
        if ($this->fp == null) {
            return;
        }

        fseek($this->fp, $this->offset);
        $data = fread($this->fp, $this->datalen);

        foreach ($this->index as $index) {
            foreach (str_split($index, 12) as $ix) {
                list(, , $pos, $len) = unpack('L3', $ix);

                if (!isset($this->data[$pos])) {
                    $this->data[$pos] = substr($data, $pos, $len + 6); // Always one extra record, for upper bound
                }
            }
        }

        fclose($this->fp);
        $this->fp = null;
    }

    /**
     * Binary search function that searches a string with records for a match.
     * Requires that the array is sorted. Since we're operating on 32-bit
     * IPs, we match the first four bytes of every string and the
     * rest is just payload. Returns the entry "n" for which the relation
     *        32bit($data[n]) <= $str < 32bit($data[n+1])
     * is true.
     *
     * Always tries to return 4 extra bytes from the next record, for an upper
     * bound. So if $reclen is 12, it tries to return 16 bytes.
     */
    private function findRecord($data, $str, $reclen)
    {
        $l = 0;
        $count = strlen($data) / $reclen;
        $h = $count - 1;

        while ($l <= $h) {
            $i = ($l + $h) >> 1;

            // Get the current record (i) and compare
            $rec = substr($data, $i * $reclen, $reclen + 4);
            $c = strcmp($str, substr($rec, 0, 4));

            // Equal? I guess we found it.
            if ($c == 0) {
                return $rec;
            // If it's more, then compare with the next record to see if that one is less
            } elseif ($c > 0) {
                // If this was the last record, then return it
                if ($i+1 >= $count) {
                    return $rec;
                }

                $rec1 = substr($data, ($i+1)*$reclen, $reclen + 4);
                $c1 = strcmp($str, substr($rec1, 0, 4));

                // Did we stumble upon the right one?
                if ($c1 == 0) {
                    // Oops. Equal with the next one. Just return.
                    return $rec1;
                } elseif ($c1 < 0) {
                    // Yep, this is the right one.
                    return $rec;
                }

                $l = $i + 1;
            } else {
                $h = $i - 1;
            }
        }

        // Never supposed to end up here - something is wrong.
        throw new Exception('Binary find failure');
    }

    /**
     * Find the index given by the IP address.
     */
    private function findIndex($ipbin)
    {
        $group = self::ipgroup($ipbin);
        $ix = $this->index[$group];

        if (strcmp($ipbin, substr($ix, 0, 4)) < 0 && $group > 0) {
            $ix = $this->index[$group-1];
        }

        if (strlen($ix) > 12) {
            $ix = $this->findRecord($ix, $ipbin, 12);
        }

        return $ix;
    }

    /**
     * Load the specific data chunk from the main data file and save it
     * to the data cache.
     */
    private function getDataEntry($pos, $len)
    {
        // If it doesn't exist in the cache, load it
        if (!isset($this->data[$pos])) {
            fseek($this->fp, $pos + $this->offset);
            $this->data[$pos] = fread($this->fp, $len + 6);  // Always one extra record, for upper bound
        }

        return $this->data[$pos];
    }

    /**
     * Lookup a 4-byte binary IP string and return the ISO country.
     */
    public function lookupbin($ipbin)
    {
        if (
            strlen($this->lastentry) == 10 &&
            strcmp($ipbin, substr($this->lastentry, 0, 4)) >= 0 &&
            strcmp($ipbin, substr($this->lastentry, 6, 4)) < 0
        ) {
            $isoName = substr($this->lastentry, 4, 2);
            return [
                'short' => $isoName,
                'full' => array_key_exists($isoName, $this->fullNames) ? $this->fullNames[$isoName] : 'Unknown'
            ];
        }

        list(, , $pos, $len) = unpack('L3', $this->findIndex($ipbin));
        $data = $this->getDataEntry($pos, $len);
        $this->lastentry = $this->findRecord($data, $ipbin, 6);
        $isoName = substr($this->lastentry, 4, 2);
        return [
            'short' => $isoName,
            'full' => array_key_exists($isoName, $this->fullNames) ? $this->fullNames[$isoName] : 'Unknown'
        ];
    }

    /**
     * Lookup an IP address and return the ISO country.
     */
    public function lookup($ip)
    {
        return $this->lookupbin(inet_pton($ip));
    }
}
