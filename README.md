# docker-apache-php-mysql-ldap

Imagem Docker de Apache 2.4 com PHP 7.4 preparada para aplicações PHP que utilizam MySQL e LDAP. Inclui extensões mysqli, pdo_mysql, ldap, zip e gd, além do mod_rewrite habilitado no Apache.

## Especificações técnicas

- **Apache**: Apache HTTP Server 2.4
- **PHP**: 7.4
- **Extensões PHP incluídas**:
  - mysqli
  - pdo_mysql
  - ldap
  - zip
  - gd
- **Módulos Apache habilitados**:
  - mod_rewrite
- **DocumentRoot padrão**: `/var/www/html`

## Pull da imagem no GHCR

Autenticação e pull:
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
docker pull ghcr.io/marcelofmatos/docker-apache-php-mysql-ldap:latest
```

Tags disponíveis: `latest`, ou tags específicas de versão conforme releases.

## Uso rápido

Executar o container para desenvolvimento:
```bash
docker run -d --name web \
  -p 8080:80 \
  -e TZ=America/Sao_Paulo \
  -v $PWD/src:/var/www/html \
  ghcr.io/marcelofmatos/docker-apache-php-mysql-ldap:latest
```

Acessar: http://localhost:8080

**Recomendação para produção**: publicar atrás de um proxy reverso com TLS (Nginx, Traefik ou similar). Exponha apenas a porta interna 80 do container para a rede privada.

## Configurações para produção

### Portas
- **80** (interno do container). Use TLS no proxy reverso para expor na porta 443.

### Volumes recomendados
- **Código da aplicação**: `./src:/var/www/html`
- **Configurações Apache**: `./apache/conf.d:/etc/apache2/conf-enabled`
- **Configurações PHP**: `./php/conf.d:/usr/local/etc/php/conf.d`
- **Logs Apache**: `./logs:/var/log/apache2`

### Variáveis de ambiente típicas
Expostas para a aplicação via `$_ENV` ou `getenv()`:

**Banco de dados**:
- `DB_HOST`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`

**LDAP**:
- `LDAP_URL` (ex: `ldap://ldap.example.com:389`)
- `LDAP_BASE_DN` (ex: `dc=example,dc=org`)
- `LDAP_BIND_DN` (ex: `cn=admin,dc=example,dc=org`)
- `LDAP_BIND_PASSWORD`

**Runtime**:
- `TZ` (ex: `America/Sao_Paulo`)
- `APP_ENV` (ex: `production`, `staging`, `development`)

### Configurações PHP customizadas

Configure via arquivos `.ini` montados em `/usr/local/etc/php/conf.d`.

Exemplo `uploads.ini`:
```ini
upload_max_filesize=64M
post_max_size=64M
memory_limit=256M
max_execution_time=120
```

### Logs

Monte o diretório `./logs` em `/var/log/apache2` e configure rotação no host ou via driver de logging do Docker:

```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
```

### Usuário e permissões

Garanta que o UID e GID do host tenham permissão de escrita nos volumes montados. Opcionalmente, especifique o usuário no compose:

```yaml
user: "1000:1000"
```

## Exemplos de docker-compose.yml

### Exemplo 1: Web + MySQL

```yaml
version: "3.9"

services:
  web:
    image: ghcr.io/marcelofmatos/docker-apache-php-mysql-ldap:latest
    container_name: web
    depends_on:
      - db
    ports:
      - "8080:80"
    environment:
      TZ: America/Sao_Paulo
      APP_ENV: production
      DB_HOST: db
      DB_NAME: app
      DB_USER: app
      DB_PASSWORD: change_me
    volumes:
      - ./src:/var/www/html:rw
      - ./apache/conf.d:/etc/apache2/conf-enabled:ro
      - ./php/conf.d:/usr/local/etc/php/conf.d:ro
      - ./logs:/var/log/apache2
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://localhost/ || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  db:
    image: mysql:8.0
    container_name: db
    environment:
      MYSQL_ROOT_PASSWORD: change_me
      MYSQL_DATABASE: app
      MYSQL_USER: app
      MYSQL_PASSWORD: change_me
    volumes:
      - db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h localhost -p$$MYSQL_ROOT_PASSWORD --silent"]
      interval: 30s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  db_data:
```

### Exemplo 2: Web + MySQL + OpenLDAP

```yaml
version: "3.9"

services:
  ldap:
    image: osixia/openldap:1.5.0
    container_name: ldap
    environment:
      LDAP_ORGANISATION: Example Org
      LDAP_DOMAIN: example.org
      LDAP_ADMIN_PASSWORD: change_me
    ports:
      - "389:389"
    volumes:
      - ldap_data:/var/lib/ldap
      - ldap_config:/etc/ldap/slapd.d
    restart: unless-stopped

  web:
    image: ghcr.io/marcelofmatos/docker-apache-php-mysql-ldap:latest
    container_name: web
    depends_on:
      - db
      - ldap
    ports:
      - "8080:80"
    environment:
      TZ: America/Sao_Paulo
      APP_ENV: production
      DB_HOST: db
      DB_NAME: app
      DB_USER: app
      DB_PASSWORD: change_me
      LDAP_URL: ldap://ldap:389
      LDAP_BASE_DN: dc=example,dc=org
      LDAP_BIND_DN: cn=admin,dc=example,dc=org
      LDAP_BIND_PASSWORD: change_me
    volumes:
      - ./src:/var/www/html:rw
      - ./apache/conf.d:/etc/apache2/conf-enabled:ro
      - ./php/conf.d:/usr/local/etc/php/conf.d:ro
      - ./logs:/var/log/apache2
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://localhost/ || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  db:
    image: mysql:8.0
    container_name: db
    environment:
      MYSQL_ROOT_PASSWORD: change_me
      MYSQL_DATABASE: app
      MYSQL_USER: app
      MYSQL_PASSWORD: change_me
    volumes:
      - db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h localhost -p$$MYSQL_ROOT_PASSWORD --silent"]
      interval: 30s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  db_data:
  ldap_data:
  ldap_config:
```

**Dica**: armazene credenciais em arquivos `.env` e restrinja permissões no host (`chmod 600 .env`).

## Extensões PHP disponíveis

As seguintes extensões estão pré-instaladas:
- mysqli
- pdo_mysql
- ldap
- zip

Verificação rápida:
```bash
docker run --rm ghcr.io/marcelofmatos/docker-apache-php-mysql-ldap:latest php -m | grep -E "mysqli|pdo_mysql|ldap|zip"
```

## mod_rewrite habilitado

O módulo mod_rewrite está habilitado para suportar front controllers e URLs amigáveis.

### Checagem
```bash
docker exec -it web a2query -m rewrite
```

### Teste com .htaccess no DocumentRoot
```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^ index.php [L]
```

## CI/CD com GitHub Actions

O repositório inclui workflows automatizados para:
- Build e push da imagem no GHCR
- Versionamento semântico automático
- Deploy em Docker Swarm

[![Release and Build](https://github.com/marcelofmatos/docker-apache-php-mysql-ldap/actions/workflows/release-and-build.yml/badge.svg)](https://github.com/marcelofmatos/docker-apache-php-mysql-ldap/actions/workflows/release-and-build.yml)

### Workflow de build e publicação

O workflow `release-and-build.yml` cria releases semânticas e publica multi-arch (linux/amd64, linux/arm64):

```yaml
name: 🚀 Release and build
on:
  workflow_dispatch:
    inputs:
      version_type:
        type: choice
        options:
          - patch
          - minor
          - major
```

Para criar uma nova release:
1. Acesse **Actions** → **🚀 Release and build**
2. Clique em **Run workflow**
3. Selecione o tipo de incremento de versão
4. Aguarde o build e publicação automática

## Boas práticas de segurança e configuração

### Segurança
- ✅ Publique atrás de proxy reverso com TLS
- ✅ Restrinja exposição de portas ao mínimo necessário
- ✅ Não armazene segredos no repositório (use `.env` com permissões restritas ou gerenciadores de segredos)
- ✅ Utilize `security_opt: no-new-privileges:true`
- ✅ Configure rede interna dedicada para comunicação entre containers
- ✅ Implemente política de firewall no host

### Confiabilidade
- ✅ Use `healthcheck` para detecção de falhas
- ✅ Configure `restart: unless-stopped`
- ✅ Defina rotação de logs com `json-file` ou agregadores
- ✅ Mantenha tags específicas de versão para previsibilidade

### Configuração
- ✅ Defina timezone via `TZ`
- ✅ Configure locale conforme necessário pela aplicação
- ✅ Ajuste UID e GID para evitar problemas de permissões
- ✅ Evite rodar como root quando possível
- ✅ Atualize a imagem periodicamente para patches de segurança

## Troubleshooting

### 403 Forbidden
- Verifique permissões do volume `./src` montado em `/var/www/html`
- Confirme diretivas `AllowOverride` nas configurações do Apache
- Valide propriedade dos arquivos (UID/GID)

### Reescrita de URL não funciona
- Confirme que mod_rewrite está habilitado: `docker exec web a2query -m rewrite`
- Verifique se `.htaccess` existe e está correto
- Valide `AllowOverride All` na configuração do VirtualHost

### Conexão com MySQL falha
- Valide que os serviços estão na mesma rede do Docker Compose
- Confirme variáveis de ambiente: `DB_HOST`, `DB_USER`, `DB_PASSWORD`
- Aguarde o healthcheck do MySQL estar saudável
- Verifique logs: `docker logs db`

### Conexão com LDAP falha
- Valide `LDAP_URL` (formato: `ldap://hostname:port`)
- Confirme `LDAP_BIND_DN` e `LDAP_BIND_PASSWORD`
- Teste conectividade: `docker exec web ldapsearch -x -H ldap://ldap:389 -b "dc=example,dc=org"`
- Verifique logs do container LDAP

### Logs não aparecem
- Confirme montagem do volume: `./logs:/var/log/apache2`
- Verifique permissões de escrita no diretório `./logs` no host
- Use `docker logs web` para logs do container

---

**Repositório**: https://github.com/marcelofmatos/docker-apache-php-mysql-ldap  
**Registry**: https://github.com/marcelofmatos/docker-apache-php-mysql-ldap/pkgs/container/docker-apache-php-mysql-ldap  
**Licença**: Conforme repositório
