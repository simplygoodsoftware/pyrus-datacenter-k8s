[![PyrusLogo](https://pyrus.com/images/logo/logo_small_x2.png)](https://pyrus.com)

## Pyrus Datacenter K8S
Pyrus Datacenter K8S — безоблачная версия Pyrus, которая поставляется в виде Helm Chart и развёртывается в системе Kubernetes.\
Платформа поддерживает работу в режиме High Availability.\
Более подробную информацию о Pyrus Datacenter можно узнать в нашей [справке](https://pyrus.com/ru/help/datacenter).

## Требования
Для запуска Pyrus Datacenter вам понадобятся:
* Лицензия Pyrus Datacenter
* SSL сертификат на выбранное вами доменное имя
* Логин и пароль учётной записи вашего SMTP сервера, для отправки почтовых сообщений пользователям
  
## Конфигурация

В данном разделе описаны необходимые для запуска Pyrus Datacenter параметры установки.

### Версия Pyrus Datacenter
```
tagsContainers:
  All: 1.3.3
```

### Лицензия
```
pyrusSetupParam:
  license: <LICENSE>
```

### Эл. почта и пароль администратора Pyrus Datacenter
```
pyrusSetupParam:
  adminEmail: <ADMINEMAIL>
  adminPass: <ADMINPASSWORD>
```

### Доменное имя
```
values-ingress-dir:
  tls:
    - hosts:
        - <DOMAIN>
```

### SSL сертификат
Добавьте Kubernetes Secret с данными вашего сертификата
```
kubectl create secret generic pyrus-ssl --from-file=tls.crt=your_cert.crt --from-file=tls.key=your_key.key
```

### Параметры Ingress-NGINX
```
  allow-backend-server-header: "true"
  allow-snippet-annotations: "true"
  proxy_next_upstream: error timeout invalid_header http_502 http_503 http_504
  proxy-stream-timeout: 2m
  proxy-stream-next-upstream-timeout: 5s
  proxy-stream-next-upstream-tries: 7
  upstream-keepalive-time: 20m
```

## Резервное копирование и восстановление данных

Pyrus Datacenter поставляется с внутренней СУБД PostgreSQL, используемой для хранения данных.\
С целью обеспечения сохранности данных реализовано автоматическое резервное копирование на основе [wal-g](https://github.com/wal-g/wal-g), позволяющее выгружать копии в AWS S3 или другое S3-совместимое хранилище.\
Для работы данного функционала необходимо указать параметры S3:

```
standalonePostgreSQLBackup:
  AWS_ACCESS_KEY_ID: <ACCESSKEY>  
  AWS_SECRET_ACCESS_KEY: <SECRETKEY>  
  WALG_S3_PREFIX: s3://<S3BUCKET>/<DIRECTORY>
```

При использовании S3-совместимого хранилища, отличного от AWS S3:
```
standalonePostgreSQLBackup:
  AWS_ENDPOINT: <S3_URL>
```

### Описание процесса резервного копирования

Резервное копирование запускается автоматически.\
Полная резервная копия по умолчанию делается в 01:00 ежедневно.\
Для изменения периодичности снятия резервной копии, вы можете воспользоваться следующей SQL командой в контейнере PostgreSQL: 

```
--                    ┌───────────── min (0 - 59)
--                    │ ┌────────────── hour (0 - 23)
--                    │ │ ┌─────────────── day of month (1 - 31)
--                    │ │ │ ┌──────────────── month (1 - 12)
--                    │ │ │ │ ┌───────────────── day of week (0 - 6) (0 to 6 are Sunday to
--                    │ │ │ │ │                  Saturday, or use names; 7 is also Sunday)
--                    * * * * *
SELECT cron.schedule('0 1 * * *', $$SELECT backup_manage(RETAIN_FIND_FULL integer, WALG_DELTA_MAX_STEPS integer)$$);
```

Параметр *RETAIN_FIND_FULL* указывает количество резервных копий, сохраняемых в S3.\
По умолчанию - 7 резервных копий.
 
Параметр *WALG_DELTA_MAX_STEPS* управляет количеством шагов, на которые дельта-копия максимально отстаёт 
от полной копии.\
По умолчанию - 3 шага.

Все задания можно посмотреть sql командой:
```
select * from cron.job;
```

### Восстановление из резервной копии

Для восстановления резервной копии необходимо указать в **ENVIROMENT** контейнера *pyrus-postgres* имя точки восстановления.\
Например, для последней точки:
```
RESTORE_NAME: LATEST
```

Список резервных копий можно посмотреть командой:
```
wal-g backup-list
```

Восстановление из копии начнётся только если директория ${PGDATA} будет пустой.\
В обратном случае, процесс восстановления будет проигнорирован и система запустится из файлов расположенных в данной директории, либо инициализировать чистую базу при их отсутствии.

