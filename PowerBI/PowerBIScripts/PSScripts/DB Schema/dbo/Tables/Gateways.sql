CREATE TABLE [dbo].[Gateways] (
    [Tag]                    NVARCHAR (MAX) NULL,
    [clusterId]              NVARCHAR (MAX) NULL,
    [clusterName]            NVARCHAR (MAX) NULL,
    [type]                   NVARCHAR (MAX) NULL,
    [cloudDatasourceRefresh] NVARCHAR (MAX) NULL,
    [customConnectors]       NVARCHAR (MAX) NULL,
    [version]                NVARCHAR (MAX) NULL,
    [status]                 NVARCHAR (MAX) NULL,
    [versionStatus]          NVARCHAR (MAX) NULL,
    [contactInformation]     NVARCHAR (MAX) NULL,
    [machine]                NVARCHAR (MAX) NULL,
    [nodeId]                 NVARCHAR (MAX) NULL
);

