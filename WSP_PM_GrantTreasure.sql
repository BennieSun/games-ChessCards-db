USE RYTreasureDB
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
----------------------------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[WSP_PM_GrantTreasure]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
-- 删除存储过程
drop procedure [dbo].[WSP_PM_GrantTreasure]
GO
----------------------------------------------------------------------

CREATE PROCEDURE WSP_PM_GrantTreasure
	@MasterID INT,				-- 管理员标识
	@ClientIP VARCHAR(15),		-- 赠送地址
	@UserID INT,				-- 用户标识
	@AddGold BIGINT,			-- 赠送金币
	@Reason NVARCHAR(32)		-- 赠送原因	
WITH ENCRYPTION AS

-- 属性设置
SET NOCOUNT ON

-- 用户金币信息
DECLARE @InsureScore BIGINT
DECLARE @Score BIGINT
DECLARE @RegisterIP NVARCHAR(15)
DECLARE @RegisterDate DATETIME
DECLARE @RegisterMachine NVARCHAR(32)
DECLARE @DateNow DATETIME
DECLARE @DateID INT
DECLARE @TypeID INT

-- 执行逻辑
BEGIN
	
	-- 获取用户金币信息
	SELECT @Score = Score,@InsureScore = InsureScore FROM GameScoreInfo WHERE UserID = @UserID
	IF @InsureScore IS NULL
	BEGIN
		SELECT @RegisterIP=RegisterIP,@RegisterDate=RegisterDate,@RegisterMachine=RegisterMachine FROM RYAccountsDBLink.RYAccountsDB.dbo.AccountsInfo WHERE UserID = @UserID
		INSERT INTO GameScoreInfo(UserID,RegisterIP,RegisterDate,RegisterMachine) VALUES(@UserID,@RegisterIP,@RegisterDate,@RegisterMachine) 
	END

	-- 金币验证
	IF @InsureScore + @AddGold < 0
	BEGIN
		RETURN 1001
	END

	-- 新增记录信息
	INSERT INTO RYRecordDBLink.RYRecordDB.dbo.RecordGrantTreasure(MasterID,ClientIP,UserID,CurGold,AddGold,Reason)
	VALUES(@MasterID,@ClientIP,@UserID,@InsureScore,@AddGold,@Reason)

	-- 赠送金币
	UPDATE GameScoreInfo SET InsureScore = InsureScore + @AddGold WHERE UserID = @UserID
	
	
	SET @TypeID=15
	SET @DateNow = GETDATE()
	SET @DateID=CAST(CAST(@DateNow AS FLOAT) AS INT)
	-- 流水帐
	INSERT INTO RYTreasureDBLink.RYTreasureDB.dbo.RecordPresentInfo(UserID,PreScore,PreInsureScore,PresentScore,TypeID,IPAddress)
	VALUES(@UserID,@Score,@InsureScore,@AddGold,@TypeID,@ClientIP)
	-- 日统计
	UPDATE RYTreasureDBLink.RYTreasureDB.dbo.StreamPresentInfo SET PresentCount=PresentCount+1,PresentScore=PresentScore+@AddGold,LastDate=@DateNow
	WHERE DateID=@DateID AND UserID=@UserID AND TypeID=@TypeID 
	IF @@ROWCOUNT=0
	BEGIN
		INSERT INTO RYTreasureDBLink.RYTreasureDB.dbo.StreamPresentInfo(DateID,UserID,TypeID,PresentCount,PresentScore,FirstDate,LastDate)
		VALUES(@DateID,@UserID,@TypeID,1,@AddGold,@DateNow,@DateNow)
	END		
END
RETURN 0

GO
