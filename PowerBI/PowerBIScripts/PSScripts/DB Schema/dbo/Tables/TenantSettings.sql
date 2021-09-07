CREATE TABLE [dbo].[TenantSettings] (
    [Tag]                   NVARCHAR (MAX) NULL,
    [switchName]            NVARCHAR (MAX) NULL,
    [switchId]              NVARCHAR (MAX) NULL,
    [deniedSecurityGroups]  NVARCHAR (MAX) NULL,
    [allowedSecurityGroups] NVARCHAR (MAX) NULL,
    [isGranular]            NVARCHAR (MAX) NULL,
    [isEnabled]             NVARCHAR (MAX) NULL
);

