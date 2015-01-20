
-- --------------------------------------------------
-- Entity Designer DDL Script for SQL Server 2005, 2008, 2012 and Azure
-- --------------------------------------------------
-- Date Created: 01/17/2015 21:21:43
-- Generated from EDMX file: D:\GIT_ROOT\Protected\CSharp\ADTEntityFramework\ADTEntityFramework\ADT_Model.edmx
-- --------------------------------------------------

SET QUOTED_IDENTIFIER OFF;
GO
USE [ADT];
GO
IF SCHEMA_ID(N'dbo') IS NULL EXECUTE(N'CREATE SCHEMA [dbo]');
GO

-- --------------------------------------------------
-- Dropping existing FOREIGN KEY constraints
-- --------------------------------------------------


-- --------------------------------------------------
-- Dropping existing tables
-- --------------------------------------------------

IF OBJECT_ID(N'[dbo].[ADTMessages]', 'U') IS NOT NULL
    DROP TABLE [dbo].[ADTMessages];
GO
IF OBJECT_ID(N'[dbo].[Patients]', 'U') IS NOT NULL
    DROP TABLE [dbo].[Patients];
GO
IF OBJECT_ID(N'[dbo].[Locations]', 'U') IS NOT NULL
    DROP TABLE [dbo].[Locations];
GO

-- --------------------------------------------------
-- Creating all tables
-- --------------------------------------------------

-- Creating table 'ADTMessages'
CREATE TABLE [dbo].[ADTMessages] (
    [MessageID] nvarchar(255)  NOT NULL,
    [MessageType] nvarchar(max)  NOT NULL,
    [PreviousLocationID] nvarchar(max)  NULL,
    [LocationID] nvarchar(max)  NULL,
    [PreviousStatus] nvarchar(max)  NULL,
    [Status] nvarchar(max)  NOT NULL,
    [KickedPatientID] nvarchar(max)  NULL,
    [GeneratedTimestamp] datetime  NOT NULL,
    [MessageTimestamp] datetime  NOT NULL,
    [PatientID] nvarchar(max)  NOT NULL
);
GO

-- Creating table 'Patients'
CREATE TABLE [dbo].[Patients] (
    [PatientID] nvarchar(255)  NOT NULL,
    [FirstName] nvarchar(max)  NULL,
    [LastName] nvarchar(max)  NULL,
    [Status] nvarchar(max)  NOT NULL,
    [LocationID] nvarchar(max)  NULL
);
GO

-- Creating table 'Locations'
CREATE TABLE [dbo].[Locations] (
    [LocationID] nvarchar(255)  NOT NULL
);
GO

-- --------------------------------------------------
-- Creating all PRIMARY KEY constraints
-- --------------------------------------------------

-- Creating primary key on [MessageID] in table 'ADTMessages'
ALTER TABLE [dbo].[ADTMessages]
ADD CONSTRAINT [PK_ADTMessages]
    PRIMARY KEY CLUSTERED ([MessageID] ASC);
GO

-- Creating primary key on [PatientID] in table 'Patients'
ALTER TABLE [dbo].[Patients]
ADD CONSTRAINT [PK_Patients]
    PRIMARY KEY CLUSTERED ([PatientID] ASC);
GO

-- Creating primary key on [LocationID] in table 'Locations'
ALTER TABLE [dbo].[Locations]
ADD CONSTRAINT [PK_Locations]
    PRIMARY KEY CLUSTERED ([LocationID] ASC);
GO

-- --------------------------------------------------
-- Creating all FOREIGN KEY constraints
-- --------------------------------------------------

-- --------------------------------------------------
-- Script has ended
-- --------------------------------------------------