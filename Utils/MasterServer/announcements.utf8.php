<?php
function EchoUpdateMessage($Lang, $Rev, $MAIN_VERSION)
{
	echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|';
	switch($Lang)
	{
		case 'slv':
			echo 'Vaša verzija KaM remake-a je zastarela! Imate verzijo '.$Rev.' ampak najnovejša verzija je '.$MAIN_VERSION.'.||prosimo prenesite nadgradnjo na: https://www.kamremake.com';
			break;
		case 'srb':
			echo 'Ваш Кам Ремаке верзија није савремена! Ви користите '.$Rev.' али најновија верзија је '.$MAIN_VERSION.'. Молимо вас скините најновију верзију на сајту: https://www.kamremake.com';
			break;
		case 'kor':
			echo '귀하의 기사와 상인 다시만듬 버전이 최신버전이 아닙니다! 현재 '.$Rev.' 버전이 실행중이지만 가장 최신버전은 '.$MAIN_VERSION.' 버전입니다.|| 갱신을하기위해서는 다음 주소에서 다운로드 하여 주십시요:https://www.kamremake.com';
			break;
		case 'tur':
			echo 'Eski bir KaM Remake versiyonu kullanıyorsunuz! '.$Rev.' versiyonunu kullanıyorsunuz fakat '.$MAIN_VERSION.' versiyonu kullanılabilir durumda.||Lütfen https://www.kamremake.com adresinden güncellemeyi indiriniz.';
			break;
		case 'jpn':
			echo 'アナタのKAMリメイクのバージョンは時代遅れですよ。'.$Rev.'が実行されましている，しかし'.$MAIN_VERSION.'バージョンはより最近です。このリンク「https://www.kamremake.com」からアップデートがダウンロードされましてください。';
			break;
		case 'bel':
			echo 'Ваша версія KaM Remake ўстарэла! Вы выкарыстоўваеце '.$Rev.', а самая апошняя версія '.$MAIN_VERSION.'. ||Калі ласка загрузіце абнаўленне па адрасе: https://www.kamremake.com';
			break;
		case 'nor':
			echo 'Din versjon av KaM Remake er utdatert! Du kjører '.$Rev.' men den mest nylige versjonen er '.$MAIN_VERSION.'.||Vennligst last ned oppdateringen på: https://www.kamremake.com';
			break;
		case 'ukr':
			echo 'Ваша '.$Rev.' версія KaM Remake застаріла! Завантажте нову '.$MAIN_VERSION.' модифікацію на сайті: https://www.kamremake.com';
			break;
		case 'rom':
			echo 'Versiunea ta de KaM Remake este expirată! Acum rulezi '.$Rev.' dar cea mai recentă versiune este '.$MAIN_VERSION.'.||Te rugăm să descarci update-ul de la https://www.kamremake.com';
			break;
		case 'svk':
			echo 'Vaša verzia KaM Remake je zastaralá! Máte spustenú verziu '.$Rev.', ale posledná verzia je '.$MAIN_VERSION.'.||Prosím, stiahnite si aktualizáciu na stránke: https://www.kamremake.com';
			break;
		case 'est':
			echo 'Teie KaM Remake versioon on vana! Teie versioon on '.$Rev.' , aga viimane versioon on '.$MAIN_VERSION.'.||Palun laadige alla uuendus: https://www.kamremake.com';
			break;
		case 'bul':
			echo 'Версията на играта е с по-стара версия! Вие използвате '.$Rev.' ,но се препоръчва последната версия, която е '.$MAIN_VERSION.'.||Моля изтеглете ъпдейта от: https://www.kamremake.com';
			break;
		case 'spa':
			echo '¡La version del kam Remake está desactualizada! Estás ejecutando '.$Rev.' pero la versión más reciente es '.$MAIN_VERSION.'.||Por favor bajate la actualizacion en: https://www.kamremake.com';
			break;
		case 'ita':
			echo 'La tua versione di \'KaM Remake\' non è aggiornata! Stai utilizzando la versione '.$Rev.', mentre la più recente è '.$MAIN_VERSION.'.||Puoi scaricare l\'aggiornamento dal sito: https://www.kamremake.com.';
			break;
		case 'ptb':
			echo 'Sua versão do KaM Remake está desatualizada! Você está executando '.$Rev.' mas a versão mais recente é '.$MAIN_VERSION.'.|| Por favor, baixe a atualização em: https://www.kamremake.com';
			break;
		case 'hun':
			echo 'A KaM Remake verziód túl régi! Te a '.$Rev.' verziót futtatod, miközben a '.$MAIN_VERSION.' verzió a legújabb.||Kérlek töltsd le a játék frissítését a hivatalos oldalon: https://www.kamremake.com';
			break;
		case 'rus':
			echo 'Ваша версия игры устарела! Вы используете версию '.$Rev.' тогда как последняя доступная версия - '.$MAIN_VERSION.'.||Пожалуйста скачайте ее с сайта: https://www.kamremake.com';
			break;
		case 'cze':
			echo 'Máte zastaralou verzi KaM Remake! Používáte verzi '.$Rev.', ale nejnovější verze je '.$MAIN_VERSION.'.||Prosím, stáhněte si aktualizaci na: https://www.kamremake.com';
			break;
		case 'fre':
			echo 'La version de KaM Remake que vous utilisez n\'est pas mise à jour !|Vous avez la version '.$Rev.' alors que la version la plus récente est la '.$MAIN_VERSION.'.||Veuillez télécharger la mise à jour sur https://www.kamremake.com.';
			break;
		case 'pol':
			echo 'Twoja wersja KaM Remake jest nieaktualna! Używasz '.$Rev.' ale najnowszą jest '.$MAIN_VERSION.'.||Proszę pobrać aktualizację ze strony: https://www.kamremake.com';
			break;
		case 'dut':
			echo 'Uw KaM Remake versie is niet de nieuwste. U draait '.$Rev.' maar de meest recente versie is '.$MAIN_VERSION.'.||U kunt de nieuwste versie downloaden van: https://www.kamremake.com';
			break;
		case 'swe':
			echo 'Du har inte den senaste versionen av KaM Remake! Du kör '.$Rev.', medan den senaste versionen är '.$MAIN_VERSION.'.||Ladda ner uppdateringen här: https://www.kamremake.com';
			break;
		case 'ger':
			echo 'Deine Version des Remakes ist veraltet! Du hast '.$Rev.', die neuste ist '.$MAIN_VERSION.'.||Bitte lade das neuste Update von https://www.kamremake.com runter.';
			break;
		case 'chn':
			echo '你的骑士与商人重制版的版本已经过期！你正在运行的是 '.$Rev.' ，但最新版本是 '.$MAIN_VERSION.' 。||请在 https://www.kamremake.com 下载升级版本。';
			break;
		default:
			echo 'Your KaM Remake version is out of date! You are running '.$Rev.' but the most recent version is '.$MAIN_VERSION.'.||Please download the update at: https://www.kamremake.com';
	}
	echo '||~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
}

function EchoUsingBetaMessage($Lang, $Rev, $MAIN_VERSION)
{
	echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|';
	switch($Lang)
	{
		case 'rus':
			echo 'Рады представить Вам новую Бета версию [$C6FFB0]KaM Remake Beta '.$Rev.'[]! Надеемся Вам понравятся обновления, но надо учитывать, что это пока ранняя бета версия, в которой возможно наличие багов и ошибок.|Чтобы помочь исправить их пожалуйста не забывайте отправлять баг репорты при вылете игры с ошибкой.|Это очень поможет нам исправить ошибки и сделать игру более стабильной, так что мы сможем выпустить релиз раньше!||Want to socialise with a community of KaM players, or talk with your friends while you play? Join the KaM community teamspeak server! More information at:|[$F8A070]http://kamts.eu[]||Enjoy playing KaM Remake? Please consider [$00EEFF]donating[] to help cover our running costs and support future development. Visit [$F8A070]www.kamremake.com/donations[]';
			break;
		default:
			echo 'Welcome to new [$C6FFB0]KaM Remake Beta '.$Rev.'[]! Its an early Beta, so some bugs and errors could happen, please be patient and help to fix them by sending us crash reports after the very first error|It will really help us to make game more stable and release new version earlier!||Want to socialise with a community of KaM players, or talk with your friends while you play? Join the KaM community teamspeak server! More information at:|[$F8A070]http://kamts.eu[]|Prefer Discord? We have one too! Join us via:|[$F8A070]https://discord.gg/UkkYceR[]||Enjoy playing KaM Remake? Please consider [$00EEFF]donating[] to help cover our running costs and support future development. Visit [$F8A070]https://www.kamremake.com/donations[]';
	}
	echo '||~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
}
