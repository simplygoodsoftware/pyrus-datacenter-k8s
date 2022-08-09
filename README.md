## Общие сведения
Рекомендуется ставить pyrus в отдельный namespaces.  
Требования: ingress работает только с ingress-nginx  
  
## Для установки вам нужны следующие параметры которые нужно задать в values.yaml:
* лицензия      .Values.pyrusSetupParam.license
* доменное имя  .Values поле hosts в разделе values-ingress-dir  
  **pyrus будет работать только на первом домене в списке**
* tls сертификат можно добавить следующими способами:  
  - вы можете его добавить вручную и впоследствии сослаться на него в разделе ингреса
  - если вы планируете его ставить через функционал данного chart:  
    добавьте в директорию чарта символическую ссылку на расположение ключевой пары.  
    список файлов должен включат в себя  
    * доменноеИмя.зона.crt - открытый ключ с цепочкой  
    * доменноеИмя.зона.key - закрытый ключ  
    * доменноеИмя.зона.pem - полный комплект выше перечисленного  

## Рекомендованные параметры для ingress-nginx
```
  allow-backend-server-header: "true"
  allow-snippet-annotations: "true"
  proxy_next_upstream: error timeout invalid_header http_502 http_503 http_504
  proxy-stream-timeout: 2m
  proxy-stream-next-upstream-timeout: 5s
  proxy-stream-next-upstream-tries: 7
  upstream-keepalive-time: 20m
```
