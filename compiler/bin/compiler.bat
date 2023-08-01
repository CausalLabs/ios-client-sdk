@rem
@rem Copyright 2015 the original author or authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem      https://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

@if "%DEBUG%"=="" @echo off
@rem ##########################################################################
@rem
@rem  compiler startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%"=="" set DIRNAME=.
@rem This is normally unused
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%..

@rem Resolve any "." and ".." in APP_HOME to make it shorter.
for %%i in ("%APP_HOME%") do set APP_HOME=%%~fi

@rem Add default JVM options here. You can also use JAVA_OPTS and COMPILER_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS=

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if %ERRORLEVEL% equ 0 goto execute

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto execute

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\lib\compiler-0.39.3.jar;%APP_HOME%\lib\parser-0.39.3.jar;%APP_HOME%\lib\runtime-0.39.3.jar;%APP_HOME%\lib\slf4j-simple-1.7.30.jar;%APP_HOME%\lib\antlr4-4.7.2.jar;%APP_HOME%\lib\jcommander-1.82.jar;%APP_HOME%\lib\jmustache-1.15.jar;%APP_HOME%\lib\s3-transfer-manager-2.20.74.jar;%APP_HOME%\lib\orc-core-1.8.0.jar;%APP_HOME%\lib\hadoop-common-3.2.4.jar;%APP_HOME%\lib\httpclient5-5.2.1.jar;%APP_HOME%\lib\avro-1.11.0.jar;%APP_HOME%\lib\lambda-2.20.74.jar;%APP_HOME%\lib\s3-2.20.74.jar;%APP_HOME%\lib\sagemakerruntime-2.20.74.jar;%APP_HOME%\lib\sts-2.20.74.jar;%APP_HOME%\lib\aws-json-protocol-2.20.74.jar;%APP_HOME%\lib\aws-xml-protocol-2.20.74.jar;%APP_HOME%\lib\aws-query-protocol-2.20.74.jar;%APP_HOME%\lib\aws-core-2.20.74.jar;%APP_HOME%\lib\auth-2.20.74.jar;%APP_HOME%\lib\regions-2.20.74.jar;%APP_HOME%\lib\protocol-core-2.20.74.jar;%APP_HOME%\lib\sdk-core-2.20.74.jar;%APP_HOME%\lib\apache-client-2.20.74.jar;%APP_HOME%\lib\arns-2.20.74.jar;%APP_HOME%\lib\json-utils-2.20.74.jar;%APP_HOME%\lib\netty-nio-client-2.20.74.jar;%APP_HOME%\lib\http-client-spi-2.20.74.jar;%APP_HOME%\lib\metrics-spi-2.20.74.jar;%APP_HOME%\lib\crt-core-2.20.74.jar;%APP_HOME%\lib\profiles-2.20.74.jar;%APP_HOME%\lib\utils-2.20.74.jar;%APP_HOME%\lib\orc-shims-1.8.0.jar;%APP_HOME%\lib\hive-storage-api-2.8.1.jar;%APP_HOME%\lib\azure-storage-blob-12.22.3.jar;%APP_HOME%\lib\azure-storage-internal-avro-12.7.2.jar;%APP_HOME%\lib\azure-storage-common-12.21.2.jar;%APP_HOME%\lib\azure-core-http-netty-1.13.4.jar;%APP_HOME%\lib\azure-core-1.40.0.jar;%APP_HOME%\lib\hadoop-auth-3.2.4.jar;%APP_HOME%\lib\curator-recipes-2.13.0.jar;%APP_HOME%\lib\curator-framework-2.13.0.jar;%APP_HOME%\lib\curator-client-2.13.0.jar;%APP_HOME%\lib\zookeeper-3.4.14.jar;%APP_HOME%\lib\kerb-simplekdc-1.0.1.jar;%APP_HOME%\lib\kerb-client-1.0.1.jar;%APP_HOME%\lib\kerb-admin-1.0.1.jar;%APP_HOME%\lib\kerb-server-1.0.1.jar;%APP_HOME%\lib\kerb-common-1.0.1.jar;%APP_HOME%\lib\kerb-util-1.0.1.jar;%APP_HOME%\lib\kerb-identity-1.0.1.jar;%APP_HOME%\lib\kerby-config-1.0.1.jar;%APP_HOME%\lib\token-provider-1.0.1.jar;%APP_HOME%\lib\kerb-crypto-1.0.1.jar;%APP_HOME%\lib\kerb-core-1.0.1.jar;%APP_HOME%\lib\kerby-pkix-1.0.1.jar;%APP_HOME%\lib\slf4j-api-1.7.36.jar;%APP_HOME%\lib\commons-text-1.10.0.jar;%APP_HOME%\lib\commons-collections4-4.4.jar;%APP_HOME%\lib\fastutil-8.5.8.jar;%APP_HOME%\lib\aws-crt-0.21.12.jar;%APP_HOME%\lib\reactor-netty-http-1.0.31.jar;%APP_HOME%\lib\reactor-netty-core-1.0.31.jar;%APP_HOME%\lib\netty-handler-proxy-4.1.91.Final.jar;%APP_HOME%\lib\netty-codec-http2-4.1.91.Final.jar;%APP_HOME%\lib\netty-codec-http-4.1.91.Final.jar;%APP_HOME%\lib\netty-resolver-dns-native-macos-4.1.91.Final-osx-x86_64.jar;%APP_HOME%\lib\netty-resolver-dns-classes-macos-4.1.91.Final.jar;%APP_HOME%\lib\netty-resolver-dns-4.1.91.Final.jar;%APP_HOME%\lib\netty-handler-4.1.94.Final.jar;%APP_HOME%\lib\protobuf-java-3.19.6.jar;%APP_HOME%\lib\reload4j-1.2.22.jar;%APP_HOME%\lib\json-smart-2.4.10.jar;%APP_HOME%\lib\jersey-json-1.19.jar;%APP_HOME%\lib\jettison-1.5.4.jar;%APP_HOME%\lib\jetty-webapp-9.4.51.v20230217.jar;%APP_HOME%\lib\jetty-servlet-9.4.51.v20230217.jar;%APP_HOME%\lib\jetty-security-9.4.51.v20230217.jar;%APP_HOME%\lib\jetty-server-9.4.51.v20230217.jar;%APP_HOME%\lib\guava-30.1.1-jre.jar;%APP_HOME%\lib\opentelemetry-instrumentation-annotations-1.26.0.jar;%APP_HOME%\lib\opentelemetry-api-1.26.0.jar;%APP_HOME%\lib\jackson-datatype-jsr310-2.13.5.jar;%APP_HOME%\lib\jackson-annotations-2.13.5.jar;%APP_HOME%\lib\jackson-core-2.13.5.jar;%APP_HOME%\lib\jackson-dataformat-xml-2.13.5.jar;%APP_HOME%\lib\jackson-databind-2.13.5.jar;%APP_HOME%\lib\endpoints-spi-2.20.74.jar;%APP_HOME%\lib\annotations-2.20.74.jar;%APP_HOME%\lib\third-party-jackson-core-2.20.74.jar;%APP_HOME%\lib\antlr4-runtime-4.7.2.jar;%APP_HOME%\lib\ST4-4.1.jar;%APP_HOME%\lib\antlr-runtime-3.5.2.jar;%APP_HOME%\lib\org.abego.treelayout.core-1.0.3.jar;%APP_HOME%\lib\javax.json-1.0.4.jar;%APP_HOME%\lib\icu4j-61.1.jar;%APP_HOME%\lib\commons-lang3-3.12.0.jar;%APP_HOME%\lib\aircompressor-0.21.jar;%APP_HOME%\lib\annotations-17.0.0.jar;%APP_HOME%\lib\threeten-extra-1.7.1.jar;%APP_HOME%\lib\netty-transport-native-epoll-4.1.91.Final-linux-x86_64.jar;%APP_HOME%\lib\netty-transport-native-kqueue-4.1.91.Final-osx-x86_64.jar;%APP_HOME%\lib\netty-transport-classes-epoll-4.1.91.Final.jar;%APP_HOME%\lib\netty-transport-classes-kqueue-4.1.91.Final.jar;%APP_HOME%\lib\netty-transport-native-unix-common-4.1.94.Final.jar;%APP_HOME%\lib\netty-codec-socks-4.1.91.Final.jar;%APP_HOME%\lib\netty-codec-dns-4.1.91.Final.jar;%APP_HOME%\lib\netty-codec-4.1.94.Final.jar;%APP_HOME%\lib\netty-transport-4.1.94.Final.jar;%APP_HOME%\lib\netty-resolver-4.1.94.Final.jar;%APP_HOME%\lib\netty-buffer-4.1.94.Final.jar;%APP_HOME%\lib\netty-common-4.1.94.Final.jar;%APP_HOME%\lib\hadoop-annotations-3.2.4.jar;%APP_HOME%\lib\commons-cli-1.2.jar;%APP_HOME%\lib\commons-math3-3.1.1.jar;%APP_HOME%\lib\httpclient-4.5.13.jar;%APP_HOME%\lib\commons-codec-1.15.jar;%APP_HOME%\lib\commons-io-2.8.0.jar;%APP_HOME%\lib\commons-net-3.6.jar;%APP_HOME%\lib\commons-beanutils-1.9.4.jar;%APP_HOME%\lib\commons-collections-3.2.2.jar;%APP_HOME%\lib\javax.servlet-api-3.1.0.jar;%APP_HOME%\lib\javax.activation-api-1.2.0.jar;%APP_HOME%\lib\jetty-http-9.4.51.v20230217.jar;%APP_HOME%\lib\jetty-io-9.4.51.v20230217.jar;%APP_HOME%\lib\jetty-xml-9.4.51.v20230217.jar;%APP_HOME%\lib\jetty-util-ajax-9.4.51.v20230217.jar;%APP_HOME%\lib\jetty-util-9.4.51.v20230217.jar;%APP_HOME%\lib\jsp-api-2.1.jar;%APP_HOME%\lib\jersey-servlet-1.19.jar;%APP_HOME%\lib\jersey-server-1.19.jar;%APP_HOME%\lib\jersey-core-1.19.jar;%APP_HOME%\lib\commons-configuration2-2.1.1.jar;%APP_HOME%\lib\commons-logging-1.2.jar;%APP_HOME%\lib\re2j-1.1.jar;%APP_HOME%\lib\gson-2.9.0.jar;%APP_HOME%\lib\jsch-0.1.55.jar;%APP_HOME%\lib\spotbugs-annotations-3.1.9.jar;%APP_HOME%\lib\jsr305-3.0.2.jar;%APP_HOME%\lib\htrace-core4-4.1.0-incubating.jar;%APP_HOME%\lib\commons-compress-1.21.jar;%APP_HOME%\lib\woodstox-core-6.4.0.jar;%APP_HOME%\lib\stax2-api-4.2.1.jar;%APP_HOME%\lib\dnsjava-2.1.7.jar;%APP_HOME%\lib\accessors-smart-2.4.9.jar;%APP_HOME%\lib\failureaccess-1.0.1.jar;%APP_HOME%\lib\listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.jar;%APP_HOME%\lib\checker-qual-3.8.0.jar;%APP_HOME%\lib\error_prone_annotations-2.5.1.jar;%APP_HOME%\lib\j2objc-annotations-1.3.jar;%APP_HOME%\lib\opentelemetry-context-1.26.0.jar;%APP_HOME%\lib\httpcore5-h2-5.2.jar;%APP_HOME%\lib\httpcore5-5.2.jar;%APP_HOME%\lib\httpcore-4.4.13.jar;%APP_HOME%\lib\reactor-core-3.4.29.jar;%APP_HOME%\lib\reactive-streams-1.0.4.jar;%APP_HOME%\lib\eventstream-1.0.1.jar;%APP_HOME%\lib\azure-json-1.0.1.jar;%APP_HOME%\lib\netty-tcnative-boringssl-static-2.0.59.Final.jar;%APP_HOME%\lib\jsr311-api-1.1.1.jar;%APP_HOME%\lib\jaxb-impl-2.2.3-1.jar;%APP_HOME%\lib\jackson-jaxrs-1.9.2.jar;%APP_HOME%\lib\jackson-xc-1.9.2.jar;%APP_HOME%\lib\jackson-mapper-asl-1.9.2.jar;%APP_HOME%\lib\jackson-core-asl-1.9.2.jar;%APP_HOME%\lib\nimbus-jose-jwt-9.8.1.jar;%APP_HOME%\lib\jline-0.9.94.jar;%APP_HOME%\lib\audience-annotations-0.5.0.jar;%APP_HOME%\lib\netty-3.10.6.Final.jar;%APP_HOME%\lib\asm-9.3.jar;%APP_HOME%\lib\netty-tcnative-classes-2.0.59.Final.jar;%APP_HOME%\lib\jaxb-api-2.2.2.jar;%APP_HOME%\lib\jcip-annotations-1.0-1.jar;%APP_HOME%\lib\kerby-xdr-1.0.1.jar;%APP_HOME%\lib\stax-api-1.0-2.jar;%APP_HOME%\lib\activation-1.1.jar;%APP_HOME%\lib\kerby-asn1-1.0.1.jar;%APP_HOME%\lib\kerby-util-1.0.1.jar


@rem Execute compiler
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %COMPILER_OPTS%  -classpath "%CLASSPATH%" io.causallabs.compiler.Compiler %*

:end
@rem End local scope for the variables with windows NT shell
if %ERRORLEVEL% equ 0 goto mainEnd

:fail
rem Set variable COMPILER_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
set EXIT_CODE=%ERRORLEVEL%
if %EXIT_CODE% equ 0 set EXIT_CODE=1
if not ""=="%COMPILER_EXIT_CONSOLE%" exit %EXIT_CODE%
exit /b %EXIT_CODE%

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
