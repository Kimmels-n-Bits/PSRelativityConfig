SELECT
	[Name] = [Value]
FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
WHERE [Section] = @Section
AND [Name] = @Name