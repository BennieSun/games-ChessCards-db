USE RYAccountsDB
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[NET_PW_GetUserBaseInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
-- 删除存储过程
drop procedure [dbo].[NET_PW_GetUserBaseInfo]
GO
----------------------------------------------------------------------------------------------------

-- 获取用户基本资料
CREATE  PROCEDURE NET_PW_GetUserBaseInfo
	@dwUserID INT,                            		-- 用户ID	
	@strErrorDescribe NVARCHAR(127) OUTPUT			-- 输出信息
WITH ENCRYPTION AS

-- 属性设置
SET NOCOUNT ON

-- 帐号信息
DECLARE @UserID INT
DECLARE @Account NVARCHAR(31)
DECLARE @NikeName NVARCHAR(31)	
DECLARE @GameID	INT
DECLARE @UserMedal INT
DECLARE @UserRight INT

-- 用户资料
DECLARE @Gender TINYINT
DECLARE @UnderWrite NVARCHAR(63)

-- 帐号状态
DECLARE @Nullity BIT
DECLARE @StunDown BIT
DECLARE @AgentID INT

-- 第三方ID
DECLARE @UserUin nvarchar(32)

-- 执行逻辑
BEGIN
	-- 用户资料
	SELECT	@UserID=UserID,
		@Account=Accounts,
		@UserMedal = UserMedal,
		@NikeName = Nickname,
		@GameID=GameID,
		@Gender=Gender,
		@UnderWrite=UnderWrite,	
		@UserRight=UserRight,
		@Nullity=Nullity,
		@StunDown=StunDown,
		@AgentID=AgentID,
		@UserUin=UserUin
	FROM AccountsInfo (NOLOCK) WHERE UserID=@dwUserID
	
	-- 查询用户
	IF @UserID IS NULL
	BEGIN
		SET @strErrorDescribe= N'您的帐号不存在或者密码输入有误，请查证后再次尝试登录！'
		RETURN 1
	END

	-- 帐号禁止
	IF @Nullity<>0
	BEGIN
		SET @strErrorDescribe=N'您的帐号暂时处于冻结状态，请联系客户服务中心了解详细情况！'
		RETURN 2
	END	

	-- 帐号关闭
	IF @StunDown<>0
	BEGIN
		SET @strErrorDescribe=N'您的帐号使用了安全关闭功能，必须重新开通后才能继续使用！'
		RETURN 3
	END			
	
	-- 输出变量
	SELECT	@UserID AS UserID, 
			@Account AS Accounts,
			@NikeName AS Nickname,
			@GameID AS GameID,
			@Gender AS Gender,
			@UnderWrite AS UnderWrite,
			@UserRight AS UserRight,
			@UserMedal AS UserMedal,
			@AgentID AS AgentID,
			@UserUin AS UserUin
END

RETURN 0

GO
