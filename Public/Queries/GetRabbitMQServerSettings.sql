DECLARE @RabbitMQFQDN NVARCHAR(4000)
DECLARE @UserName NVARCHAR(4000)
DECLARE @Password NVARCHAR(4000)
DECLARE @RabbitMQTLSEnabled NVARCHAR(4000)
DECLARE @ServiceNamespace NVARCHAR(4000)

SELECT
	@RabbitMQFQDN = [is].[Value]
FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
WHERE [is].[Section] = N'Relativity.ServiceBus'
AND [is].[Name] = N'ServiceBusFullyQualifiedDomainName'

SELECT
	@UserName = [is].[Value]
FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
WHERE [is].[Section] = N'Relativity.ServiceBus'
AND [is].[Name] = N'SharedAccessKeyName'

SELECT
	@Password = [is].[Value]
FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
WHERE [is].[Section] = N'Relativity.ServiceBus'
AND [is].[Name] = N'SharedAccessKey'

SELECT
	@RabbitMQTLSEnabled = [is].[Value]
FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
WHERE [is].[Section] = N'Relativity.ServiceBus'
AND [is].[Name] = N'EnableTLSForServiceBus'

SELECT
	@ServiceNamespace = [is].[Value]
FROM [EDDS].[EDDSDBO].[InstanceSetting] AS [is]
WHERE [is].[Section] = N'Relativity.ServiceBus'
AND [is].[Name] = N'ServiceNameSpace'

SELECT
	[RabbitMQFQDN] = @RabbitMQFQDN
	,[UserName] = @UserName
	,[Password] = @Password
	,[RabbitMQTLSEnabled] = @RabbitMQTLSEnabled
	,[ServiceNamespace] = @ServiceNamespace