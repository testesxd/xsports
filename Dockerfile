
# Etapa 1: compilação do projeto
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

WORKDIR /src

COPY Xsports.csproj ./
RUN dotnet restore Xsports.csproj

COPY . ./
RUN dotnet publish Xsports.csproj -c Release -o /app/publish

# Etapa 2: execução da aplicação
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final

WORKDIR /app

COPY --from=build /app/publish ./

ENV ASPNETCORE_URLS=http://0.0.0.0:10000

EXPOSE 10000

ENTRYPOINT ["dotnet", "Xsports.dll"]
