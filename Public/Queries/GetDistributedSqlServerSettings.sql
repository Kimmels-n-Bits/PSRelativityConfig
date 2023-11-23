DROP TABLE IF EXISTS [#SqlServer]
CREATE TABLE [#SqlServer]
(
	[Name] NVARCHAR(4000) NOT NULL PRIMARY KEY
	,[SqlInstance] NVARCHAR(4000) NOT NULL
	,[SqlPort] INT NOT NULL
	,[SqlBackupDirectory] NVARCHAR(4000) NOT NULL
	,[SqlLogDirectory] NVARCHAR(4000) NOT NULL
	,[SqlDataDirectory] NVARCHAR(4000) NOT NULL
	,[SqlFullTextDirectory] NVARCHAR(4000) NOT NULL
)

DECLARE @Name NVARCHAR(4000)
DECLARE @SqlInstance NVARCHAR(4000)
DECLARE @SqlPort INT
DECLARE @SqlBackupDirectory NVARCHAR(4000)
DECLARE @SqlLogDirectory NVARCHAR(4000)
DECLARE @SqlDataDirectory NVARCHAR(4000)
DECLARE @SqlFullTextDirectory NVARCHAR(4000)

DECLARE [SqlServerCursor] CURSOR STATIC LOCAL FORWARD_ONLY READ_ONLY FOR
SELECT
	[Name] = LEFT([rs].[Name], LEN([rs].[Name]) - CHARINDEX('\', REVERSE([rs].[Name])))
	,[SqlInstance] = [rs].[Name]
	,[SqlPort] = 1433
FROM [EDDS].[EDDSDBO].[ResourceServer] AS [rs]
INNER JOIN [EDDS].[EDDSDBO].[Code] AS [c]
	ON [c].[ArtifactID] = [rs].[Type]
WHERE [c].[Name] = N'SQL - Distributed'

OPEN [SqlServerCursor]
FETCH NEXT FROM [SqlServerCursor] INTO
	@Name
	,@SqlInstance
	,@SqlPort

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT
		@SqlBackupDirectory = [is].[Value]
	FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
	WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
	AND [is].[Name] = N'BackupDirectory'
	AND [is].[MachineName] = @Name

	IF (@SqlBackupDirectory IS NULL)
	BEGIN
		SELECT
			@SqlBackupDirectory = [is].[Value]
		FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
		WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
		AND [is].[Name] = N'BackupDirectory'
		AND [is].[MachineName] = N''
	END

	SELECT
		@SqlLogDirectory = [is].[Value]
	FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
	WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
	AND [is].[Name] = N'LDFDirectory'
	AND [is].[MachineName] = @Name

	IF (@SqlLogDirectory IS NULL)
	BEGIN
		SELECT
			@SqlLogDirectory = [is].[Value]
		FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
		WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
		AND [is].[Name] = N'LDFDirectory'
		AND [is].[MachineName] = N''
	END

	SELECT
		@SqlDataDirectory = [is].[Value]
	FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
	WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
	AND [is].[Name] = N'DataDirectory'
	AND [is].[MachineName] = @Name

	IF (@SqlDataDirectory IS NULL)
	BEGIN
		SELECT
			@SqlDataDirectory = [is].[Value]
		FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
		WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
		AND [is].[Name] = N'DataDirectory'
		AND [is].[MachineName] = N''
	END

	SELECT
		@SqlFullTextDirectory = [is].[Value]
	FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
	WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
	AND [is].[Name] = N'FTDirectory'
	AND [is].[MachineName] = @Name

	IF (@SqlFullTextDirectory IS NULL)
	BEGIN
		SELECT
			@SqlFullTextDirectory = [is].[Value]
		FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
		WHERE [is].[Section] = N'kCura.EDDS.SqlServer'
		AND [is].[Name] = N'FTDirectory'
		AND [is].[MachineName] = N''
	END

	INSERT INTO [#SqlServer]
	(
		[Name]
		,[SqlInstance]
		,[SqlPort]
		,[SqlBackupDirectory]
		,[SqlLogDirectory]
		,[SqlDataDirectory]
		,[SqlFullTextDirectory]
	)
	SELECT
		[Name] = @Name
		,[SqlInstance] = @SqlInstance
		,[SqlPort] = @SqlPort
		,[SqlBackupDirectory] = @SqlBackupDirectory
		,[SqlLogDirectory] = @SqlLogDirectory
		,[SqlDataDirectory] = @SqlDataDirectory
		,[SqlFullTextDirectory] = @SqlFullTextDirectory

	FETCH NEXT FROM [SqlServerCursor] INTO
		@Name
		,@SqlInstance
		,@SqlPort
END

SELECT
	[Name]
	,[SqlInstance]
	,[SqlPort]
	,[SqlBackupDirectory]
	,[SqlLogDirectory]
	,[SqlDataDirectory]
	,[SqlFullTextDirectory]
FROM [#SqlServer]