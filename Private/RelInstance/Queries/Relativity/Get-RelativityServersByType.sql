SELECT
	[Name] = LEFT([rs].[Name], LEN([rs].[Name]) - CHARINDEX('\', REVERSE([rs].[Name])))
FROM [EDDS].[EDDSDBO].[ResourceServer] AS [rs]
INNER JOIN [EDDS].[EDDSDBO].[Code] AS [c]
	ON [c].[ArtifactID] = [rs].[Type]
WHERE [c].[Name] = @ServerType