@echo off
:: BedCommService - PostBuild.bat for BedCommService Project
::-----------------------------------------------------------
    set SkipAllDeployment=False
    set DistributionDirectory=C:\BedComm
::-----------------------------------------------------------
    :: Should be passed as arg 1 (i.e., "%1") the $(ProjectDir) argument from the VS2010 project
    :: Should be passed as arg 2 (i.e., "%2") the $(Configuration) argument from the VS2010 project
    :: Should be passed as arg 3 (i.e., "%3") the $(SolutionDir) argument from the VS2010 project
    :: Should be passed as arg 4 (i.e., "%4") the $(TargetPath) argument from the VS2010 project
::-----------------------------------------------------------
if not exist "%DistributionDirectory%"\bin goto skipping
    echo Copying %4 to "%DistributionDirectory%\bin"
    copy /Y %4 %DistributionDirectory%\bin
    goto leave
:skipping
    echo ...Skipping deployment because '%DistributionDirectory%\bin' does't exist.  
    echo    Set DistributionDirectory in PostBuild.bat to deploy after build.
    goto leave

:error
echo "=== Returning ERROR
exit /B 2

:leave
echo "=== Returning SUCCESS



