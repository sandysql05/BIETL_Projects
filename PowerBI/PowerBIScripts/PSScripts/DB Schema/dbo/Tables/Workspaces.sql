CREATE TABLE [dbo].[Workspaces] (
    [Tag]                   NVARCHAR (MAX) NULL,
    [Id]                    NVARCHAR (MAX) NULL,
    [Name]                  NVARCHAR (MAX) NULL,
    [IsReadOnly]            NVARCHAR (MAX) NULL,
    [IsOnDedicatedCapacity] NVARCHAR (MAX) NULL,
    [CapacityId]            NVARCHAR (MAX) NULL,
    [Description]           NVARCHAR (MAX) NULL,
    [Type]                  NVARCHAR (MAX) NULL,
    [State]                 NVARCHAR (MAX) NULL,
    [IsOrphaned]            NVARCHAR (MAX) NULL,
    [Users]                 NVARCHAR (MAX) NULL
);

