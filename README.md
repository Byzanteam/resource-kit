# ResourceKit

## Prerequisites

* PostgreSQL 15+

## Environments

| Name | Description | Default |
| ---- | ----------- | ------- |
| RESOURCE_KIT_DATABASE_URL | 数据库连接地址（格式：`ecto://USER:PASS@HOST/DATABASE`，[参考](https://hexdocs.pm/ecto/3.9.4/Ecto.Repo.html#module-urls)） | **required** |
| RESOURCE_KIT_ECTO_IPV6 | Ecto 是否使用 IPv6 连接数据库 | `"false"` |
| RESOURCE_KIT_SERVER_PORT | 接口服务监听的端口 | `4000` |

## Sentry

| Name | Description | Default |
| ---- | ----------- | ------- |
| RESOURCE_KIT_SENTRY_DSN | Sentry 的 DSN（为了便于管理，每个 server 单独一个 DSN） | `N/A` |
| RESOURCE_KIT_SENTRY_SERVER_NAME | Resource Kit 服务所在服务器的名字，便于排查出错的服务器 | `N/A` |

### Versions

> [!NOTE]
> Versions are set by the build pipeline

| Name | Description | Default |
| ---- | ----------- | ------- |
| APP_VERSION  | 当前服务的版本 | `N/A` |
| APP_REVISION | 当前服务的提交 | `N/A` |

## Volumes

| Path | Description |
| ---- | ----------- |
| `"/data"` | 寻找 actions 和 schemas 的基础文件目录 |
