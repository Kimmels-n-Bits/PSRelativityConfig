SELECT
	[Name] = [rs].[Name]
	,[EnableWinAuth] = IIF(SUM(IIF([c].[Name] LIKE 'Web:AD Authentication', 1, 0)) > 0, 1, 0)
FROM [EDDS].[EDDSDBO].[ResourceServer] AS [rs]
INNER JOIN [EDDS].[EDDSDBO].[Code] AS [c]
	ON [c].[ArtifactID] = [rs].[Type]
WHERE [c].[Name] LIKE 'Web%'
GROUP BY [rs].[Name]
