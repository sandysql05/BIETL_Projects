CREATE TABLE [dbo].[PremiumEvictionMetrics] (
    [Tag]                                           NVARCHAR (MAX) NULL,
    [EvictionMetrics.capacityObjectId]              NVARCHAR (MAX) NULL,
    [EvictionMetrics.timestamp]                     NVARCHAR (MAX) NULL,
    [EvictionMetrics.activeModelCount]              NVARCHAR (MAX) NULL,
    [EvictionMetrics.inactiveModelCount]            NVARCHAR (MAX) NULL,
    [EvictionMetrics.averageIdleTimeBeforeEviction] NVARCHAR (MAX) NULL
);

