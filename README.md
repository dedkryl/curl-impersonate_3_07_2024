## Проект
Настоящий проект ответвлен от curl-impersonate с целью поддержки
новых версий браузеров.

В настоящий момент (август 2024) добавлена поддержка
- curl_chrome127 : Chrome 127.0.6533.72 (для Ubuntu 20.04) и Safari 17.5,
- curl_chrome127_win :  Chrome 127.0.6533.72 (для Windows 11),
- curl_safari17_5 : Safari 17.5 (Mac OS Monterey 12.7.6),
- curl_safari17_1_arm : Safari 17.1 (Apple M2, Sonoma 14.1),
- curl_safari17_1_iphone : Safari 17.1 (iPhone 15 Pro, iOS version 17.5.1).

## Изменения главной ветки

Изменения в структуре проекта связаны с более удобным контролем за внесением изменений в используемые библиотеки.
BoringSSl и cURL собираются из веток https://github.com/dedkryl/boringssl_3_07_2024 и https://github.com/dedkryl/curl_3_07_2024
соответственно. К ним уже приложены патчи https://github.com/lwthiker/curl-impersonate/tree/main/chrome/patches
 и внесены описанные ниже изменения.
 
 Для предварительного анализа сигнатур новых версий браузеров использовались инструменты:
 1) WireShark для анализа ClientHello (CipherSuites, Extensions) и (для Chrome) расшифровка HTTP2 c использованием сохраненных ключей.
 2) Трассировка HTTP2 локальным nghttpd с Self Signed Key.
 
 По результатам анализа в формируемые на основе предыдущих версий скрипты - были внесены изменения. 
 
 Наиболее существенные:
 
 1) Состав и порядок следования CipherSuites, 
 2) Использование опции --tls-permute-extensions для Chrome 127,
 3) Добавление X25519Kyber768Draft00 (Pre-standards version of Kyber768)  в опцию --curves для Chrome 127,
 4) Изменения содержания и порядка следования в заголовках HTTP,
 5) Добавлении опции --h2-settings-style.
 
 Выявлены существенные отличия в содержании кадра SETTINGS между Chrome 127 , Safari 17.5,  Safari 17.1 и curl-impersonate с curl 8.1.1.
 Требуемые настройки в последней версии curl - отсутствуют, поэтому была проведена доработка используемого  curl_3_07_2024 с добавлением
 опции --h2-settings-style.
 
 Значения опции:
 
- "Chrome127_style" - для Chrome 127.0.6533.72 соответствует:

   SETTINGS_HEADER_TABLE_SIZE;

   SETTINGS_ENABLE_PUSH; (if http2_no_server_push)

   SETTINGS_INITIAL_WINDOW_SIZE;

   SETTINGS_MAX_HEADER_LIST_SIZE;
   
- "Safari17_5_style" - для Safari 17.5  соответствует:
 
   SETTINGS_MAX_CONCURRENT_STREAMS;
 
   SETTINGS_INITIAL_WINDOW_SIZE;

- "Safari17_1_style" - для Safari 17.1  соответствует:
 
   SETTINGS_ENABLE_PUSH;

   SETTINGS_INITIAL_WINDOW_SIZE;
   
   SETTINGS_MAX_CONCURRENT_STREAMS;

- "Default_style"  соответствует:
 
   SETTINGS_HEADER_TABLE_SIZE;

   SETTINGS_ENABLE_PUSH; (if http2_no_server_push)

   SETTINGS_MAX_CONCURRENT_STREAMS;

   SETTINGS_INITIAL_WINDOW_SIZE;

   SETTINGS_MAX_HEADER_LIST_SIZE;


   Отсутствие опции в скрипте - Default_style.

## Сборка и запуск

git clone https://github.com/dedkryl/curl-impersonate_3_07_2024.git

cd curl-impersonate_3_07_2024/

./chrome_ubuntu_build_and_install.sh

curl_chrome127 www.example.com

вывод html... 

## Сборка и запуск образа Docker

git clone https://github.com/dedkryl/curl-impersonate_3_07_2024.git

cd curl-impersonate_3_07_2024/

sudo docker build   -t your_tag chrome/

sudo docker run --rm your_tag curl_chrome127 https://www.example.com
