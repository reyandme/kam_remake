# .md and .html files
For section icons to work, Markdown (.md) and HTML files need to be in the same directory as Readme/GUI_*.gif files.

Please translate .md files (not HTML), it's convenient for everyone including yourself.

# instructions
1. Go to https://github.com/jgm/pandoc/releases/ 
1. Download windows .zip version
1. Change path to where you extracted pandoc, and run the commands:
```
cd kam_remake_git\Docs\Readme
pandoc.exe -s -f markdown getting-started_eng.md -o Readme_eng.html --metadata title="Getting started with Knights and Merchants: Remake"
pandoc.exe -s -f markdown getting-started_ger.md -o Readme_ger.html --metadata title="Erste Schritte mit Knights and Merchants: Remake"
pandoc.exe -s -f markdown getting-started_pol.md -o Readme_pol.html --metadata title="Pierwsze kroki z Knights and Merchants: Remake"
pandoc.exe -s -f markdown getting-started_rus.md -o Readme_rus.html --metadata title="Начало работы с Knights and Merchants: Remake"
```

# how to fix broken links in top bar
Link must be lowercase and with spaces replaced with hyphens (-)
Example: if your section is called "First Section", then the link will be `#first-section`