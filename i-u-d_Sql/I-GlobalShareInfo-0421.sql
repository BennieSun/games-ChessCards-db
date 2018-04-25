USE [RYTreasureDB]
GO

INSERT INTO [dbo].[GlobalShareInfo]
           ([ShareID]
           ,[ShareName]
           ,[ShareAlias]
           ,[ShareNote]
           ,[CollectDate])
     VALUES
           (500,
           'Google充值',
           'GOOGLE',
           'Google充值服务'
           ,GETDATE()),
		   
           (501,
           '苹果充值',
           'IOS',
           '苹果充值服务'
           ,GETDATE()),

		   (502,
           '威富通充值',
           'SWIFTPASS',
           '威富通充值服务'
           ,GETDATE())
GO

alter table [dbo].ShareDetailInfo add ThirdOrderID nvarchar(50)

go
