# kuma_dash_preset
Скрипт импорта/экспорта дашбордов, пресетов и сохраненных запросов для KUMA

\* *14.08.2023 - добавлен импорт экспорт Пресетов*

\* *06.12.2024 - добавлен импорт экспорт Сохраненных запросов, проверка импортируемого файла в KUMA и проверка результата импорта*

Предварительно нужно:
- установленный пакет `jq`, для установки на ubuntu: `sudo apt-get update && sudo apt-get install jq`
- права запуска для скрипта, `chmod +x kuma_dash_preset.sh`

При импорте-экспорте нужно указывать полный путем, пример, /root/DNS_EXPORT_CLEAR.json

**Параметры запуска скрипта `kuma_dash_preset.sh`**

`-exportDash "<Dashboard Name>" </path/File Export Name.json>` -- экспортировать панель мониторинга в файл JSON (имя панели мониторинга должно быть УНИКАЛЬНЫМ! и используйте ", если в имени есть пробелы)

`-importDash <File Export Name.json>` -- импортировать панель мониторинга в KUMA

*Иногда после импорта требуется зайти в новый дашборд в режиме редактирования и проверить указаны ли во всех виджетах верные хранилища, затем сохранить и снова обновить. Либо сделать его универсальным в веб-интерфейсе KUMA.*

`-deleteDash "<Dashboard Name>"` -- удалить панель мониторинга из KUMA (используйте " если в имени есть пробелы)

`-exportPreset "<Preset Name>" </path/File Export Name.json>` -- экспортировать пресет в файл JSON (имя должно быть УНИКАЛЬНЫМ! и используйте ", если в имени есть пробелы)

`-importPreset <File Export Name.json>` -- импорт пресета в KUMA

`-exportSearch "<Search Name>" </path/File Export Name.json>` -- экспортировать пресет в файл JSON (имя должно быть УНИКАЛЬНЫМ! и используйте ", если в имени есть пробелы)

`-importSearch <File Export Name.json` -- импорт пресета в KUMA

Пример импорта:
`./kuma_dash_preset.sh -import /root/CheckPointCEF_EXPORT_CLEAR(kuma2-0).json`

Для массовой загрузки можно воспользоваться циклом:
`for i in $(ls *json); do ./kuma_dash_preset.sh -importSearch $i; done`
