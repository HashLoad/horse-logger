FROM debian:stable-slim

# Instala o compilador do Free Pascal (fpc) e ferramentas necessárias
RUN apt-get update && apt-get install -y \
    fpc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Define diretório de trabalho
WORKDIR /app

# Copia o código-fonte completo
COPY . .

# Compila o exemplo utilizando o fpc do Linux
RUN fpc -Mdelphi -Sh -O2 -FE/app/samples/console -Fu"/app/src;/app/modules/horse/src;/app/modules/horse-utils-clientip/src" /app/samples/console/ConsoleSample.dpr

# Expõe a porta 9000
EXPOSE 9000

# Executa o servidor de exemplo
CMD ["/app/samples/console/ConsoleSample"]
