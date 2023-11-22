SELECT
	[Name] = [Value]
FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
WHERE [Section] = 'kCura.LicenseManager'
AND [Name] = 'Instance'