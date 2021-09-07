CREATE TABLE [dbo].[PremiumQueryMetrics] (
    [Tag]                           NVARCHAR (MAX) NULL,
    [QueryMetrics.timestamp]        NVARCHAR (MAX) NULL,
    [QueryMetrics.capacityObjectId] NVARCHAR (MAX) NULL,
    [QueryMetrics.datasetId]        NVARCHAR (MAX) NULL,
    [SumtotalHighWaitCount]         NVARCHAR (MAX) NULL,
    [SumtotalWaitCount]             NVARCHAR (MAX) NULL,
    [SummaxWaitTime]                NVARCHAR (MAX) NULL,
    [SummaxDuration]                NVARCHAR (MAX) NULL,
    [SummaxCPUTime]                 NVARCHAR (MAX) NULL,
    [SumaverageWaitTime]            NVARCHAR (MAX) NULL,
    [SumaverageDuration]            NVARCHAR (MAX) NULL,
    [SumaverageCPUTime]             NVARCHAR (MAX) NULL
);

