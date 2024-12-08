**Brought to you by Krom, Lewin and Rey**

---

[Системные требования](#системные-требования) · [Установка](#установка) · [Игра](#игра) · [F.A.Q.](#часто-задаваемые-вопросы) · [Community and feedback](#community-and-feedback) · [Известные ошибки](#известные-ошибки-и-неточности) · [Исходные коды](#исходные-коды) · [Создатели](#создатели) · [Правовые обязательства](#правовые-обязательства)

---

### ![](Readme/GUI_0310.gif) Системные требования

- операционная система: Microsoft Windows или Linux с Wine;
- любой двухъядерный процессор;
- 256MB оперативной памяти;
- 3D ускоритель с поддержкой OpenGL версии 1.5 или выше

### ![](Readme/GUI_0303.gif) Установка

1. Obtain the original game (Knights and Merchants: The Peasants Rebellion):
	- Installers from original CD and GOG.com should just work.
	- If you bought TPR from Steam, you need to run TPR at least once, otherwise Remake's installer will be unable to detect it.
	- If you use Linux, see <https://github.com/reyandme/kam_remake/wiki/Game-installation-on-Linux>
1. Run the Remake installer and follow the installation instructions.
1. The KaM Remake uses OpenGL for graphics. In case of visual issues or inability to launch the game, visit your graphics card manufacturer site to get the latest drivers available.
1. Launch the mod - KaM_Remake.exe or from the Desktop/Start Menu if you chose to create shortcuts.

### ![](Readme/GUI_0312.gif) Игра

#### Multiplayer
To start a game, go to Multiplayer. You can pick any unused server, if you want to start a new lobby, or you can join an existing lobby.

You can also create a local (LAN) server, using "Create server" button.

If you want to create a new dedicated server for our community, see details here: <https://github.com/reyandme/kam_remake/blob/master/Docs/Readme/technical.md>

#### Keyboard shortcuts
**The following shortcuts are available in the game:**

- **Esc** закрыть открытое сообщение, или открытый раздел игрового меню
- **F1-F4** открыть соответствующий раздел игрового меню
- **F5-F8** увеличить скорость игры в x1 / x3 / x6 / x10 раз (speedup multiplier can be changed in game's XML settings file)
- **F11** показать меню и отладочную панель
- **0-9** выбрать здание или воина, назначенного с помощью соответствующей комбинации Ctrl + 0-9
- **B** установить метку на карте. Метку видите только вы и ваши союзники
- **Spacebar** перейти к месту события открытого сообщения
- **P** пауза
- Holding the **T** button in multiplayer mode, will show player nicknames over their units
- **Delete** удалить открытое сообщение
- **←↑→↓** курсорные кнопки используются для перемещения по карте
- **Колесико мыши** увеличивает и уменьшает масштаб
- **Backspace ←** установит масштаб обратно на 100%

Для более подробной информации о клавиатурных сокращениях посетите соответствующую страницу Wiki игры:  
<https://github.com/reyandme/kam_remake/wiki/Controls>

#### Installing add-on maps:
Maps should be added (in Remake's directory) to Maps (for singleplayer), MapsMP (for multiplayer); there is also a directory for Campaigns.

You can find additional community-made maps at <https://knights-tavern.com>.

#### Добавление собственной музыки:
Вы можете скопировать ваши MP3/OGG файлы в каталог "KaM Remake\Music", и они будут автоматически добавлены в список воспроизведения.

# ![](Readme/GUI_0311.gif) Часто задаваемые вопросы
**Падение игры без сообщения:**  
Если у вас в игре низкая частота смены кадров, это может быть вызвано старыми или отсутствующими драйверами OpenGL. Проверьте вашу версию драйверов OpenGL, посмотрев в главном меню в верхний левый угол, версия должна быть как минимум 1.5.x. Если она ниже, то необходимо обновить драйвера вашей видеокарты (драйвера можно скачать на сайте производителя).

**Низкая частота смены кадров:**  
If you have ridiculously low framerate in game it might be because your OpenGL drivers are out of date. See the OpenGL version information in the top-left corner of the main menu, it should be at least 1.5.x. If it is less you need to update your graphics card drivers (check your card manufacturers website).

**Ошибки:**  
Иногда, когда происходит нечто непредвиденное, вы получаете сообщение «Произошла ошибка в приложении». Пожалуйста, нажмите кнопку «Отправить отчет об ошибке», чтобы отправить нам информацию, которая поможет диагностировать проблему. Введите свое имя и адрес электронной почты в форме, если вы хотите, чтобы мы могли связаться с вами по поводу ошибки.

**Anything else:**  
See <https://www.kamremake.com/faq/>

## ![](Readme/GUI_0323.gif) Community and Feedback

Join our community at <https://discord.gg/UkkYceR>. We would love your comments, suggestions, thanks, etc.  
If you can offer some help in Delphi coding, documentation, game artwork, sounds, translation or ideas for improvement - please drop us an email or write on Discord. 

# ![](Readme/GUI_0304.gif) Известные ошибки и неточности

Осадной мастерской не функционирует.  

# ![](Readme/GUI_0308.gif) Исходные коды

Исходные коды KaM Remake доступны по адресу:  
<https://github.com/reyandme/kam_remake>  
По этому адресу доступно Wiki с информацией об игре:  
<https://github.com/reyandme/kam_remake/wiki>  
Мы призываем вас сообщать нам о найденных ошибках используя встроенный интерфейс:  
<https://github.com/reyandme/kam_remake/issues>  
или на нашем канале Discord.

# ![](Readme/GUI_0314.gif) Создатели

Ведущий программист  - Krom (<mailto:kromster80@gmail.com>)  
Программист - Rey (<mailto:kamremake.rey@gmail.com>) 
Программист - Lewin (<mailto:lewinjh@gmail.com>)  
Программист - Toxic (Advanced AI and random map generator)
и многое другое...
 
Особая благодарность Александру, который написал ядро структуры кода в 2008 г.  
Спасибо StarGazer, который нарисовал Рынок, новые курсоры и иконки для интерфейса, а также Malin за нарисованные товары для рынка.  
Огромное спасибо сообществу КаМ и его активным членам (Free_sms_kam, Harold, Humbelum, JBSnorro, The Knight, Litude (Real Hotdog), Merchator, Nick, Thunderwolf, Vas, andreus, ZblCoder и многим другим), кто помогал нам с декодированием, советами, идеями и поддержкой.  
В игре использованы иконки от famfamfam и FatCow.  

# ![](Readme/GUI_0322.gif) Правовые обязательства

1. Коммерческое использование продукта запрещено.  
2. Все использованные имена, символы или другие защищенные авторскими правами материалы, являются собственностью их владельцев.  
3. Мы не несем ответственности, если данный мод (KaM Remake) нанесет ущерб программному или аппаратному обеспечению вашего компьютера.  
4. По очевидным причинам, издание и/или распространение KaM Remake, в любой форме, недопустимо без данного Readme файла.  
5. Вы можете загрузить данный мод на ваш сайт/сервер/домашнюю страницу, но, пожалуйста, предварительно сообщите нам об этом.  
6. Мы предполагаем, что вы (пользователь/игрок) располагайте собственной лицензионной копией игры "Knights and Merchants: The Peasants Rebellion", в противном случае вам следует купить игру, прежде чем вы начнете играть в KaM Remake. Невыполнение этого требования будет нарушением лицензионного соглашения.  
