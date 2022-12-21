# Glpi no Vagrant

GLPI é um software bastante usado hoje em dia para fazer o gerenciamento de filas de atendimento, service desk e acompanhamento de inventário de ativos de TI. Este repositório têm como objetivo demonstrar a instalação automatizada de uma instalação completa do GLPI, dividido entre várias partes.

![Dashboard do GLPI](glpi_10.png)

## Informações iniciais

Primeiramente é preciso informar que esse repositório faz uso de scripts bash e não usa ansible, então sempre é recomendado destruir toda a estrutura (`vagrant destroy -f`) e recriar novamente (`vagrant up`) após alterações nos scripts ou no próprio Vagrantfile, para garantir a idempotência.

Adicionalmente, foi criado um arquivo `.env` onde ficam as configurações iniciais básicas necessárias para se subir a instalação do GLPI. Elas não são muitas, e basicamente se resumem a usuários e senhas, e a versão do GLPI que será instalada.

### Opiniões assumidas sobre algumas configurações

Uma coisa para qual esse repositório foi pensado foi a de ser possível customizar a instalação do cluster de algumas maneiras bem simples, e mantendo-se o restante da instalação o mais automatizado possível. Desta forma, algumas decisões pessoais foram tomadas. As mais importantes são:

1. O Vagrant utiliza alguns plugins para fazer o gerenciamento do arquivo de hosts das máquinas tanto nos guests quanto no host. Desta forma, ocasionalmente podem aparecer solicitações de senha, para a alteração do arquivo de hosts, que é bloqueada para usuários administrativos na maioria dos SOs. Isso foi colocado para facilitar os acessos usando somente um endereço de DNS e não pelo IP;

2. Foi usada uma imagem do Rocky Linux 9.1 instalada através do box `generic/rocky9` pois é uma variante do RHEL (e do CentOS por tabela) muito robusta e *feature compatible* com o RHEL;

3. Foi decidido usar o Vagrant em conjunto com o VirtualBox. Poderia ser usado outro Virtualizador (até o Virt Manager) mas esta foi uma decisão tomada unicamente por questão de prática com o uso do VirtualBox;

4. Foi decidido usar scripts em bash em vez de receitas do Ansible, pois como ferramenta de estudo, é bastante clara a sequência de execução dos comandos de instalação. No futuro, uma versão alternativa usando Ansible será disponibilizada;

5. As redes locais das interfaces NAT das máquinas virtuais do arquivo `Vagrantfile` foram alteradas para `10.254.0.0/16`, assim, evitando conflitos com as diversas configurações de rede local que possam existir por aí;

6. Foi criada uma interface de rede do tipo _host only_ no range `192.168.56.0/24` para permitir que as máquinas conversem entre si sem precisar sair do VirtualBox. Adicionalmente, é possível acessar os nós do cluster e os serviços disponibilizados via LoadBalancer do cluster.

### Construção da imagem base

Foram feitas algumas alterações na imagem base, para alterar os locales da máquina, adicionar repositórios extras e adicionalmente instalar o Cockpit (que pode ser acessado na porta 9090 das máquinas em questão).

### Instalação do Balanceador HAProxy

Não há muito segredo na instalação do HAProxy. Foi feita a geração de um certificado autoassinado para usar com a conexão SSL, foi adicionado um arquivo de configuração padrão para o HAProxy e foi feito um ajuste no SELinux para liberar a porta 8081 para acesso das estatísticas. Adicionalmente, as portas https e 8081 foram adicionadas no firewalld.

### Instalação do Banco de Daos MariaDB

Para o banco MariaDB, foi feita a instalação, alteração da senha de root e o hardening da instalação do banco de dados e também foi criado um usuário para o GLPI no banco. Adicionalmente foram adicionadas as informações de *Time Zone* dentro do banco mysql e liberada a permissão para o usuário do GLPI de consultar as referidas entradas. A porta do mariadb foi adicionada ao firewalld.

### Instalação da Máquina de Aplicação

Para a instalação da máquina de aplicação, foi adicionado o repositório REMI para podermos usar a versão mais recente do PHP em nossa instalação. Adicionalmente foi instalado um plugin do Cockpit para permitir a navegação de arquivos. Posteriormente foi instalado o PHP, o Apache e o módulo mod_security do Apache.

Após a instalação dos pacotes, foi feita a configuração do VirtualHost do Apache para apontar para a pasta onde estará instalado o GLPI, a instalação das dependências do GLPI e então feito o download do código do GLPI do repositório oficial.

Adicionalmente, nesta instalação fizemos a separação das pastas config, files e log para outra pasta fora do VirtualHost, para que não possa ser acessada indevidamente em alguma situação de exposição da máquina.

Em seguida foi feita a configuração do PHP para os parâmetros necessários para o bom funcionamento do GLPI. Após, foi feita a liberação de vários parâmetros de segurança do SELinux em relação ao Apache, necessários para permitir o acesso do Apache e do PHP ao envio de e-mails, conexão ao banco e ldap.

Em seguida, é executado comando de checagem dos requisitos para a instalação do GLPI e então gerada a estrutura básica do banco de dados, necessária para o funcionamento do GLPI.

Em seguimento a isso, as senhas dos usuários iniciais do GLPI são alterados para `semsenha`.

Por último é feita a aplicação de ajustes de permissão de acesso aos arquivos e pastas do GLPI, no SELinux e no sistema de arquivos, a liberação da porta http do Apache no firewalld e a exposição das configurações do GLPI, para uso posterior.

## Acessos

Esta instalação cria várias portas de acesso às várias VMs criadas nesse Vagrant.

Para acessar o GLPI em si, o acesso pode ser feito no endereço [https://glpi.local](https://glpi.local). Os usuários são `glpi`, `tech`, `post-only` e para todos a senha é `semsenha`.

Para acessar o painel do HAProxy, o acesso pode ser feito no endereço [http://haproxy.glpi.local:8081/glpi-stats](http://haproxy.glpi.local:8081/glpi-stats). O usuário e a senha para acesso são `admin`.

Para acessar os painéis do Cockpit de cada máquina, o usuário e a senha são `vagrant` e os endereços são os seguintes:
- [https://haproxy.glpi.local:9090](https://haproxy.glpi.local:9090)
- [https://mariadb.glpi.local:9090](https://mariadb.glpi.local:9090)
- [https://app.glpi.local:9090](https://app.glpi.local:9090)

Por último, para testar o mod_security, é possível através da URL [https://app.glpi.local/?testparam=teste](https://app.glpi.local/?testparam=teste).

## Destruindo o ambiente de estudos e liberando os recursos alocados

Para apagar a instalação e todos os recursos criados, é só usar o comando abaixo. Também pode ser usado caso você queira recriar o ambiente do zero.

```bash
vagrant destroy -f
```

# Considerações finais

Como dito mais acima, este repositório é um esforço de estudo de como fazer deploy de uma instalação do GLPI simulando um ambiente de produção e todas as situações passadas por mim neste processo foram documentadas ou neste README ou através de comentários nos arquivos dos scripts, que são separados segundo as fases que estão sendo efetuadas no momento, para deixar mais claro e organizado.

Em tempo, esse deploy não foi testado em um ambiente Windows, somente em um ambiente Linux (Linux Mint 20.2 Uma). Caso você encontre algum problema com a execução deste repositório em outros ambientes, sinta-se à vontade de enviar contribuições e/ou até PRs com correções ou adições ao script.