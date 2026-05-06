# 🗄️ Portal B2B - Estrutura de Base de Dados (DDL)

Este repositório contém a documentação e os scripts oficiais de definição de dados (DDL) para o projeto **Portal B2B**. Como o ecossistema utiliza uma arquitetura de microsserviços com um banco de dados PostgreSQL partilhado, este repositório serve como a **"Única Fonte da Verdade" (Single Source of Truth)** para a estrutura do esquema.

---

## 🏗️ Responsabilidades do DBA (Equipe de Banco de Dados)

* **Gestão de Esquema:** Criação, alteração e manutenção de tabelas, índices e restrições.
* **Padronização:** Garantir que todos os serviços sigam os mesmos padrões de nomenclatura e tipos de dados.
* **Controle de Acessos:** Gestão das permissões para o utilizador de manutenção (`db_portal_b2b`) e utilizador de aplicação (`svc_portal_b2b`).
* **Integridade:** Validar se as alterações propostas pelas equipas de microsserviços não geram redundância ou conflitos.

---

## 🔐 Dados de Ligação (Ambiente de Integração)

| Parâmetro | Valor |
| :--- | :--- |
| **Host** | `34.29.84.207` |
| **Porta** | `5432` |
| **Database** | `portal_b2b` |
| **Esquema (Schema)** | `portal_b2b` |
| **Utilizador DBA** | `db_portal_b2b` |
| **Utilizador App** | `svc_portal_b2b` |

> [!IMPORTANT]
> **REGRA INEGOCIÁVEL:** Os microsserviços **não possuem permissão** para criar ou alterar tabelas (DDL). O `auto-migrate` (ou equivalente) do seu ORM **deve estar desativado**. Qualquer alteração estrutural deve ser solicitada à equipa de BD.

---

## 📏 Padrões de Desenvolvimento

Para manter a consistência entre os 9 microsserviços, adotamos as seguintes regras:

1.  **Nomenclatura:** Utilizar `snake_case` (ex: `nome_do_campo`).
2.  **Prefixos de Tabelas:** Todas as tabelas devem ser prefixadas com o nome do serviço correspondente.
    * Ex: `usuarios_perfil`, `pedidos_item`, `logistica_entrega`.
3.  **Identificadores (IDs):** Utilizar obrigatoriamente `UUID` (gerados via `uuid-ossp`).
4.  **Datas:** Todas as tabelas devem conter os campos `criado_em` e `atualizado_em` com `TIMESTAMP WITH TIME ZONE`.
5.  **Moeda:** Valores monetários devem usar o tipo `DECIMAL(15,2)` ou `NUMERIC`. **Nunca** usar `FLOAT`.

---

## 📂 Organização do Repositório

```text
.
├── scripts/
│   ├── 01-setup/           # Inicialização do schema e extensões (ex: UUID)
│   ├── 02-tabelas/         # Definições de tabelas separadas por domínio
│   └── 03-permissoes/      # Scripts de GRANT para o utilizador svc_portal_b2b
├── docs/                   # Diagramas ERD e documentação técnica
└── README.md               # Este ficheiro
