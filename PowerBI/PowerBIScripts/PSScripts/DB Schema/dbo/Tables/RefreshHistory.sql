CREATE TABLE [dbo].[RefreshHistory] (
    [Tag]                  NVARCHAR (MAX) NULL,
    [refreshType]          NVARCHAR (MAX) NULL,
    [id]                   NVARCHAR (MAX) NULL,
    [serviceExceptionJson] NVARCHAR (MAX) NULL,
    [DatasetName]          NVARCHAR (MAX) NULL,
    [WorkspaceID]          NVARCHAR (MAX) NULL,
    [status]               NVARCHAR (MAX) NULL,
    [startTime]            NVARCHAR (MAX) NULL,
    [endTime]              NVARCHAR (MAX) NULL,
    [DatasetID]            NVARCHAR (MAX) NULL
);

