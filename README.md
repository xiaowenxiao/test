＃适用于Kubernetes的ONLYOFFICE DocumentServer

该存储库包含一组文件，用于将ONLYOFFICE DocumentServer部署到Kubernetes集群中。

＃＃ 介绍

-您必须安装Kubernetes。请检查[参考]（https://kubernetes.io/docs/setup/）来设置Kubernetes。
-您还应该具有本地配置的`kubectl`副本。请参阅[this]（https://kubernetes.io/docs/tasks/tools/install-kubectl/）指南，了解如何安装和配置`kubectl`。
-您应该安装Helm v3，请按照[此处]（https://helm.sh/docs/intro/install/）的说明进行安装。

##部署先决条件

### 1.安装永久性存储

安装NFS服务器预配器

``
$ helm install nfs-server stable / nfs-server-provisioner \
  --set persistence.enabled = true \
  --set persistence.storageClass = PERSISTENT_STORAGE_CLASS \
  --set persistence.size = PERSISTENT_SIZE
```

-`PERSISTENT_STORAGE_CLASS`是您的Kubernetes集群中可用的持久性存储类

  不同提供商的持久性存储类：
  -亚马逊EKS：`gp2`
  -Digital Ocean：`do-block-storage`
  -IBM Cloud：缺省`ibmc-file-bronze`。[更多存储类]（https://cloud.ibm.com/docs/containers?topic=containers-file_storage）
  -Yandex Cloud：“ yc-network-hdd”或“ yc-network-ssd”。[更多详细信息]（https://cloud.yandex.ru/docs/managed-kubernetes/operations/volumes/manage-storage-class）
  -minikube：“标准”

-“ PERSISTENT_SIZE”是nfs持久存储类的所有持久存储的总大小。您可以将大小表示为以下后缀中的一个整数：`T`，`G`，`M`，`Ti`，`Gi`，`Mi`。例如：`8Gi`。

在Helm [此处]（https://github.com/helm/charts/tree/master/stable/nfs-server-provisioner#nfs-server-provisioner）上查看有关安装NFS Server Provisioner的更多详细信息。

创建持久卷声明

``
$ kubectl apply -f ./pvc/ds-files.yaml
```

注意：默认的“ nfs”持久卷声明为8Gi。您可以在“ spec.resources.requests.storage”部分的“ ./pvc/ds-files.yaml”文件中进行更改。至少应比“ PERSISTENT_SIZE”小5％左右。对于ONLYOFFICE DocumentServer的每100个活动用户，建议永久使用8Gi或更高的存储空间。

验证`ds-files`状态

``
$ kubectl获取pvc ds文件
```

输出量

```
名称状态容量能力访问模式存储分类年龄
ds-files Bound pvc-XXXXXXXX-XXXXXXXXX-XXXX-XXXXXXXXXXXX 8Gi RWX nfs 1m
```

### 2.部署RabbitMQ

要将RabbitMQ安装到您的集群，请运行以下命令：

``
$舵机安装rabbitmq stable / rabbitmq
```
在此处[https://github.com/helm/charts/tree/master/stable/rabbitmq#rabbitmq）中查看有关通过Helm安装RabbitMQ的更多详细信息。

### 3.部署Redis

要将Redis安装到您的集群，请运行以下命令：

``
$ helm install redis稳定/ redis \
  --set cluster.enabled = false \
  --set usePassword = false
```

在此处[https://github.com/helm/charts/tree/master/stable/redis#redis）中查看有关通过Helm安装Redis的更多详细信息。

### 4.部署PostgreSQL

下载ONLYOFFICE DocumentServer数据库方案：

``
wget https://raw.githubusercontent.com/ONLYOFFICE/server/master/schema/postgresql/createdb.sql
```

从中创建配置图：

``
$ kubectl创建configmap init-db-scripts \
  --from-file =。/ createdb.sql
```

要将PostgreSQL安装到您的集群，请运行以下命令：

```
$ helm安装postgresql稳定版/ postgresql \
  --set initdbScriptsConfigMap = init-db-scripts \
  --set postgresqlDatabase = postgres \
  --set persistence.size = PERSISTENT_SIZE
```

这里的“ PERSISTENT_SIZE”是PostgreSQL持久卷的大小。例如：`8Gi`。

建议对ONLYOFFICE DocumentServer的每100个活动用户至少使用2Gi的持久性存储。

在此处[https://github.com/helm/charts/tree/master/stable/postgresql#postgresql）中查看有关通过Helm安装PostgreSQL的更多详细信息。

### 5.部署StatsD
*此步骤是可选的。如果您不想运行StatsD *，则可以完全跳过＃6步骤

部署StatsD配置图：
```
$ kubectl apply -f ./configmaps/statsd.yaml
```
部署StatsD窗格：
```
$ kubectl apply -f ./pods/statsd.yaml
```
部署`statsd`服务：
```
$ kubectl apply -f ./services/statsd.yaml
```
在ONLYOFFICE DocumentServer中允许statsD指标：

将./configmaps/documentserver.yaml文件中的`data.METRICS_ENABLED`字段设置为`“ true”`值

##部署ONLYOFFICE DocumentServer

### 1.部署ONLYOFFICE DocumentServer许可证

-如果您具有有效的ONLYOFFICE DocumentServer许可证，请从文件中创建秘密的“许可证”。

    ``
    $ kubectl创建秘密通用许可证
      --from-file =。/ license.lic
    ```

    注意：源许可证文件名应为“ license.lic”，因为此名称将用作创建的机密中的字段。

-如果您没有ONLYOFFICE DocumentServer许可证，请使用以下命令创建空的秘密`license`：

    ``
    $ kubectl创建秘密通用许可证
    ```

### 2.部署ONOFFOFFICE DocumentServer参数

部署DocumentServer configmap：

``
$ kubectl apply -f ./configmaps/documentserver.yaml
```

使用JWT参数创建`jwt`秘密

``
$ kubectl创建秘密的通用jwt
  --from-literal = JWT_ENABLED = true \
  --from-literal = JWT_SECRET = MYSECRET
```

“ MYSECRET”是用于验证对ONLYOFFICE文档服务器的请求中的JSON Web令牌的密钥。

### 3.部署DocumentServer

部署`spellchecker`部署：

``
$ kubectl apply -f ./deployments/spellchecker.yaml
```

使用以下命令验证“ spellchecker”部署是否正在运行所需数量的Pod。

``
$ kubectl获取部署拼写检查器
```

输出量

```
姓名可用年龄
拼写检查器2/2 2 2 1m
```

部署拼写检查器服务：

``
$ kubectl apply -f ./services/spellchecker.yaml
```

部署示例服务：

``
$ kubectl apply -f ./services/example.yaml
```

部署docservice：

``
$ kubectl apply -f ./services/docservice.yaml
```

部署`docservice`部署：

``
$ kubectl apply -f ./deployments/docservice.yaml
```

使用以下命令验证docservice部署是否正在运行所需数量的Pod。

``
$ kubectl获取部署文档服务
```

输出量

```
姓名可用年龄
docservice 2/2 2 2 1m
```

部署`converter`部署：

``
$ kubectl apply -f ./deployments/converter.yaml
```

使用以下命令验证“转换器”部署是否正在运行所需数量的Pod。

``
$ kubectl获取部署转换器
```

输出量

```
姓名可用年龄
转换器2/2 2 2 1m
```

默认情况下，“ docservice”，“ converter”和“ spellchecker”部署由2个容器组成。

要扩展docservice部署，请使用以下命令：

``
$ kubectl scale -n默认部署docservice --replicas = POD_COUNT
```

其中POD_COUNT是docservice pod的数量

可以按比例缩放`converter`和`spellchecker`部署：

``
$ kubectl scale -n默认部署转换器--replicas = POD_COUNT
```

``
$ kubectl scale -n默认部署拼写检查器--replicas = POD_COUNT
```

### 4.部署DocumentServer示例（可选）

*此步骤是可选的。如果您不想运行DocumentServer Example *，则可以完全跳过＃4步骤。

部署示例configmap：

``
$ kubectl apply -f ./configmaps/example.yaml
```

部署示例pod：

``
$ kubectl apply -f ./pods/example.yaml
```

### 5.公开DocumentServer

#### 5.1通过服务公开DocumentServer（仅HTTP）
*如果要通过HTTPS公开DocumentServer，请跳过＃5.1步骤*

这种类型的暴露具有最低的性能开销，它创建了一个负载平衡器来访问DocumentServer。
如果您使用外部TLS终止，并且在k8s集群中没有其他WEB应用程序，则使用这种类型的暴露。

部署`documentserver`服务：

``
$ kubectl apply -f ./services/documentserver-lb.yaml
```

运行下一个命令以获取`documentserver`服务IP：

``
$ kubectl获取服务文件服务器-o jsonpath =“ {。status.loadBalancer.ingress [*]。ip}”
```

之后，仅在http：// DOCUMENTSERVER-SERVICE-IP /上将提供ONLYOFFICE DocumentServer。

如果服务IP为空，请尝试获取`documentserver`服务主机名

``
kubectl获取服务文档服务器-o jsonpath =“ {。status.loadBalancer.ingress [*]。hostname}”
```

在这种情况下，只能从http：// DOCUMENTSERVER-SERVICE-HOSTNAME /获取ONLYOFFICE DocumentServer。


#### 5.2通过Ingress公开DocumentServer

#### 5.2.1安装Kubernetes Nginx入口控制器

要将Nginx Ingress Controller安装到您的集群，请运行以下命令：

``
$ helm install nginx-inress stable / nginx-ingress --set controller.publishService.enabled = true，controller.replicaCount = 2
```

在[这里]（https://github.com/helm/charts/tree/master/stable/nginx-ingress#nginx-ingress）中查看有关通过Helm安装Nginx Ingress的更多详细信息。

部署`documentserver`服务：

``
$ kubectl apply -f ./services/documentserver.yaml
```

#### 5.2.2通过HTTP公开DocumentServer

*如果要通过HTTPS公开DocumentServer，请跳过＃5.2.2步骤*

与通过服务进行公开相比，这种公开具有更多的性能开销，它还创建了一个负载平衡器来访问DocumentServer。 
如果您使用外部TLS终止，并且在k8s集群中有多个WEB应用程序，则使用此类型。您可以使用一组入口实例和一个负载均衡器。它可以优化入口点性能并减少您的集群付款，因为提供商可以为每个负载均衡器收取费用。

部署文档服务器入口

``
$ kubectl apply -f ./ingresses/documentserver.yaml
```

运行下一个命令以获取`documentserver`入口IP：

``
$ kubectl获取入口文档服务器-o jsonpath =“ {。status.loadBalancer.ingress [*]。ip}”
```

之后，ONLYOFFICE DocumentServer可以从http：// DOCUMENTSERVER-INGRESS-IP /获取。

如果入口IP为空，请尝试获取`documentserver`入口主机名

``
kubectl获取入口文档服务器-o jsonpath =“ {。status.loadBalancer.ingress [*]。hostname}”
```

在这种情况下，只能在http：// DOCUMENTSERVER-INGRESS-HOSTNAME /中获得ONLYOFFICE DocumentServer。

#### 5.2.3通过HTTPS公开DocumentServer

这种暴露类型为DocumentServer启用内部TLS终止。

使用ssl证书创建`tls`秘密。

将ssl证书和私钥放入“ tls.crt”和“ tls.key”文件中，然后运行：

``
$ kubectl创建秘密的通用tls \
  --from-file =。/ tls.crt \
  --from-file =。/ tls.key
```

打开`。/ ingresses / documentserver-ssl.yaml`并输入域名，而不是`example.com`。

部署文档服务器入口

``
$ kubectl apply -f ./ingresses/documentserver-ssl.yaml
```

运行下一个命令以获取`documentserver`入口IP：

``
$ kubectl获取入口文档服务器-o jsonpath =“ {。status.loadBalancer.ingress [*]。ip}”
```

如果入口IP为空，请尝试获取`documentserver`入口主机名

``
kubectl获取入口文档服务器-o jsonpath =“ {。status.loadBalancer.ingress [*]。hostname}”
```

通过DNS提供商将`documentserver`入口IP或主机名与您的域名相关联。

之后，仅在https：//您的域名/上将提供ONOFFOFFICE DocumentServer。

### 6.更新ONLYOFFICE DocumentServer
#### 6.1准备更新

下一个脚本创建一个作业，该作业将关闭服务，清除缓存文件并清除数据库中的表。
下载ONLYOFFICE DocumentServer数据库脚本以进行数据库清理：

``
$ wget https://raw.githubusercontent.com/ONLYOFFICE/server/master/schema/postgresql/removetbl.sql
```

从中创建配置图：

``
$ kubectl创建配置映射remove-db-scripts --from-file =。/ removetbl.sql
```

运行作业：

``
$ kubectl apply -f ./jobs/prepare4update.yaml
```

成功运行后，作业会自动终止其吊舱，但您必须手动清理作业本身：

``
$ kubectl删除作业prepare4update
```
#### 6.2更新DocumentServer映像

更新部署映像：
```
$ kubectl设置映像部署/拼写检查器\
  spellchecker = onlyoffice / 4testing-ds-spellchecker：DOCUMENTSERVER_VERSION

$ kubectl设置映像部署/转换器\
  converter = onlyoffice / 4testing-ds-converter：DOCUMENTSERVER_VERSION

$ kubectl设置映像部署/ docservice \
  docservice = onlyoffice / 4testing-ds-docservice：DOCUMENTSERVER_VERSION \
  proxy = onlyoffice / 4testing-ds-proxy：DOCUMENTSERVER_VERSION
```
DOCUMENTSERVER_VERSION是ONLYOFFICE DocumentServer的docker映像的新版本。
