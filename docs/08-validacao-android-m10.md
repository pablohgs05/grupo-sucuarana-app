# M10 — Validação real Android offline

## Objetivo

Validar em um aparelho Android real que o MVP funciona sem conectividade e que
os dados locais sobrevivem a interrupções normais do uso: fechamento do app,
force stop e reinicialização do aparelho.

Esta etapa é um teste de campo controlado. Ela não altera regras de negócio e
não deve usar dados reais de ocorrências, vítimas, equipes ou localizações.

## Build a validar

Use exclusivamente um APK gerado a partir da branch/commit em validação.

O workflow **Android Field Build** gera um APK de debug e publica o arquivo como
artifact do GitHub Actions. O nome do arquivo inclui o SHA curto do commit para
evitar testar uma build diferente da que foi registrada no checklist.

> O APK é de teste e usa assinatura de debug. Ele não é uma build de produção.

### Como obter o APK

No GitHub:

1. abra **Actions**;
2. abra o workflow **Android Field Build**;
3. escolha a execução correspondente ao commit que será validado;
4. na seção **Artifacts**, baixe `grupo-sucuarana-m10-<sha>`;
5. extraia o arquivo `.apk`.

Durante a PR do M10, o mesmo workflow também gera o APK da cabeça da PR. Depois
do merge, ele gera novamente a build da `dev`, permitindo uma validação final
do commit efetivamente integrado.

### Como instalar

Opção simples: copie o APK para o aparelho, abra o arquivo e permita a
instalação desta fonte apenas para a instalação de teste.

Com Android Platform-Tools e depuração USB habilitada, também é possível usar:

```powershell
adb devices
adb install -r .\grupo-sucuarana-m10-<sha>.apk
```

Antes de cada rodada formal, confirme que o SHA no nome do APK corresponde ao
SHA registrado no checklist.

Registre antes de iniciar:

- commit/SHA:
- nome do artifact:
- modelo do aparelho:
- versão do Android:
- data do teste:
- responsável pelo teste:

Não registrar IMEI, número de série, telefone pessoal, conta Google ou outros
identificadores do aparelho.

## Dados de teste

Criar somente um caso fictício. Sugestão:

- título: `Teste M10 Offline`;
- pessoa: `Pessoa Fictícia M10`;
- local: `Área Fictícia M10`;
- equipe: `Equipe Fictícia A`;
- recurso: `Recurso Fictício A`;
- narrativas sem nomes, documentos, telefones ou coordenadas reais;
- duas imagens sem conteúdo pessoal ou operacional, criadas apenas para o teste.

Não usar o PDF real do cliente como fixture, anexo ou screenshot do teste.

## Critério geral

Cada caso deve ser marcado como:

- **PASS** — comportamento esperado confirmado;
- **FAIL** — comportamento esperado não ocorreu;
- **BLOCKED** — não foi possível executar por limitação externa;
- **N/A** — caso não aplicável ao aparelho.

Em caso de FAIL, registrar apenas:

1. ID do teste;
2. ação realizada;
3. comportamento observado;
4. comportamento esperado;
5. screenshot sem dados reais, se ajudar;
6. se o problema é reproduzível.

## Checklist obrigatório

| ID | Teste | Procedimento | Resultado esperado | Status |
| --- | --- | --- | --- | --- |
| M10-01 | Instalação limpa | Instalar o APK de teste e abrir o app. | App inicia sem crash e a Home é exibida. | |
| M10-02 | Criação totalmente offline | Ativar modo avião antes de criar o relatório e preencher identificação + primeiras seções. | Criação e navegação funcionam sem rede. | |
| M10-03 | Autosave | Alterar um campo e aguardar o indicador **Salvo no dispositivo**. | Alteração é persistida localmente. | |
| M10-04 | Force stop | Após M10-03, usar **Configurações > Apps > Grupo Suçuarana > Forçar parada** e abrir novamente. | Rascunho continua disponível e os valores preenchidos permanecem. | |
| M10-05 | Retomada da seção | Parar o app em uma seção intermediária e reabrir. | Formulário retorna à seção estável correspondente, sem voltar indevidamente ao início. | |
| M10-06 | Campo condicional | Marcar uma opção como **Sim**, preencher detalhes, trocar para **Não**, depois voltar para **Sim**. | Detalhe fica oculto enquanto inativo e reaparece preservado quando a condição volta a Sim. | |
| M10-07 | Anexos persistentes | Adicionar duas imagens fictícias, definir legendas e reordená-las. Fazer force stop e reabrir. | Imagens, legendas e ordem continuam intactas. | |
| M10-08 | Remoção de anexo | Remover uma das imagens e reabrir o relatório. | Anexo removido não reaparece e o relatório continua íntegro. | |
| M10-09 | Revisão | Completar as 17 etapas e tocar **Revisar relatório**. | Resumo completo abre; relatório continua draft até confirmação explícita. | |
| M10-10 | Editar pela revisão | Na revisão, usar **Editar** em uma seção, alterar um dado e voltar à revisão. | App retorna à seção correta e a revisão reflete o novo valor. | |
| M10-11 | Confirmar revisão | Confirmar a revisão. | Relatório sai do estado de rascunho e fica disponível na Home com ação de PDF. | |
| M10-12 | Preview do PDF | Abrir **Visualizar PDF** ainda em modo avião. | PDF institucional é gerado e exibido sem rede. | |
| M10-13 | Conteúdo do PDF | Conferir capa, sumário, seções 1–6, Anexo 01 e imagens seguintes. | Estrutura aparece na ordem esperada, sem caminhos locais do Android. | |
| M10-14 | Compartilhamento offline | No preview, tocar **Compartilhar** em modo avião. | Share sheet do Android abre com o PDF anexado; não é necessário concluir envio para serviço online. | |
| M10-15 | Impressão offline | No preview, tocar **Imprimir** e usar o framework de impressão do Android ou **Salvar como PDF**, se disponível. | Diálogo de impressão abre sem crash e recebe o documento. | |
| M10-16 | Reinicialização | Com relatório e anexos salvos, reiniciar o aparelho e abrir o app mantendo modo avião. | Relatório, seção salva e anexos continuam disponíveis. | |
| M10-17 | Reabertura do PDF | Depois da reinicialização, abrir novamente o preview. | PDF volta a ser gerado com os mesmos dados e anexos. | |
| M10-18 | Ausência de backend | Permanecer em modo avião durante toda a sessão e editar/salvar/revisar/gerar PDF. | Nenhuma função crítica do MVP depende de backend. | |

## Testes de interrupção recomendados

Executar pelo menos dois:

- bloquear a tela durante o preenchimento e retornar;
- mandar o app para segundo plano após uma alteração e voltar;
- fazer force stop depois de o indicador mostrar **Salvo no dispositivo**;
- alternar entre seções rapidamente depois de editar um campo.

O objetivo é validar persistência após interrupções normais. Não desligar o
aparelho à força durante escrita de armazenamento.

## Limite conhecido — não confundir com falha do M10

SQLite e os anexos persistentes protegem contra fechamento do app, force stop,
reinício do Android e perda de conectividade.

Eles **não** protegem contra:

- desinstalação do aplicativo;
- **Limpar armazenamento/dados** nas configurações do Android;
- perda, dano ou reset de fábrica do aparelho.

Não executar essas ações esperando recuperação dos dados. Backup/sincronização
entre dispositivos é uma decisão do M11.

## Validação visual do PDF

O PDF deve ser conferido com dados fictícios e deve apresentar:

- capa;
- sumário;
- cabeçalho e rodapé nas páginas internas;
- Informações Gerais;
- Descrição da Ocorrência;
- Desenvolvimento do emprego da equipe;
- Recursos Utilizados;
- Conclusão;
- Anexo 01 com a triagem digital;
- anexos de imagem em sequência;
- nenhuma exposição do caminho local do arquivo.

A marca textual `G.S.` continua temporária até o cliente fornecer o logotipo
oficial aprovado.

## Critério de saída do M10

M10 pode ser considerado aprovado quando:

1. M10-01 a M10-18 estiverem PASS, exceto itens realmente N/A/BLOCKED com
   justificativa;
2. não existir perda reproduzível de relatório ou anexo em fechamento, force
   stop ou reinicialização;
3. o fluxo crítico funcionar em modo avião;
4. o PDF puder ser visualizado e entregue ao framework de compartilhamento e
   impressão do Android;
5. qualquer problema encontrado tiver sido corrigido e retestado na build
   correspondente.

## Registro final

Preencher ao encerrar:

- build/SHA aprovado:
- aparelho/Android:
- PASS:
- FAIL:
- BLOCKED:
- N/A:
- observações:
- decisão: **M10 APROVADO / M10 NÃO APROVADO**
