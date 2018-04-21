USE RYTreasureDB
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------
-- �һ���ֵ
CREATE PROCEDURE NET_PW_FilledExchange
	@strOperUserID    INT,					-- @OperUserID 
	@strAccounts	  NVARCHAR(31),			-- ��ֵ�û�
	@strGameID		  INT,					-- GAMEID
	@strOrdersID	  NVARCHAR(32),			--�������
	@strThirdOrderID  NVARCHAR(50),			--�������������
	@strShareID		  INT,					--ShareID
	@strPayAmount	  DECIMAL(18,2),		--֧�����
	@strCurrency      DECIMAL(18,2),		--����
	@strClientIP	  NVARCHAR(15),			--��ֵ��ַ	
	@strErrorDescribe NVARCHAR(127) OUTPUT	--�����Ϣ
WITH ENCRYPTION AS

-- ��������
SET NOCOUNT ON

-- �˺�����&������Ϣ����
DECLARE @Accounts NVARCHAR(31)
DECLARE @GameID INT
DECLARE @UserID INT

-- �ʺ�����
DECLARE @Nullity TINYINT
DECLARE @StunDown TINYINT

-- ������Ϣ
DECLARE @OperUserID INT
DECLARE @ShareID INT
DECLARE @OrderAmount DECIMAL(18,2)
DECLARE @DiscountScale DECIMAL(18,2)
DECLARE @IPAddress NVARCHAR(15)
DECLARE @Currency DECIMAL(18,2)
DECLARE @OrderID NVARCHAR(50)

-- ��Ʒ��Ϣ
DECLARE @ProductID NVARCHAR(100)
DECLARE @Price DECIMAL(18,2)
DECLARE @AttachCurrency DECIMAL(18,2)

-- �û���Ϣ
DECLARE @Score BIGINT

-- ������Ϣ
DECLARE @Rate INT
DECLARE @PresentCurrency DECIMAL(18,2)

-- ִ���߼�
BEGIN

	IF (@strOrdersID IS NOT NULL and @strOrdersID != '')
	BEGIN
		-- ������ѯ
		SELECT @OperUserID=OperUserID,@ShareID=ShareID,@UserID=UserID,@GameID=GameID,@Accounts=Accounts,
			@OrderID=OrderID,@OrderAmount=OrderAmount,@DiscountScale=DiscountScale,@Currency=Currency 
		FROM OnLineOrder WHERE OrderID=@strOrdersID

		-- ��������
		IF @OrderID IS NULL 
		BEGIN
			SET @strErrorDescribe=N'��Ǹ����ֵ���������ڡ�'
			RETURN 1
		END

		-- �����ظ�
		IF EXISTS(SELECT OrderID FROM ShareDetailInfo(NOLOCK) WHERE OrderID=@strOrdersID) 
		BEGIN
			SET @strErrorDescribe=N'�˶����ѷ��͹���Ϸ�ҡ�'
			RETURN 0
		END
	END
	ELSE
	BEGIN
		-- ��֤�û�
		SELECT @UserID=UserID,@GameID=GameID,@Accounts=Accounts,@Nullity=Nullity,@StunDown=StunDown
		FROM RYAccountsDBLink.RYAccountsDB.dbo.AccountsInfo
		WHERE Accounts=@strAccounts

		IF @UserID IS NULL
		BEGIN
			SET @strErrorDescribe=N'��Ǹ����Ҫ��ֵ���û��˺Ų����ڡ�'
			RETURN 1
		END

		IF @Nullity=1
		BEGIN
			SET @strErrorDescribe=N'��Ǹ����Ҫ��ֵ���û��˺���ʱ���ڶ���״̬������ϵ�ͻ����������˽���ϸ�����'
			RETURN 2
		END

		IF @StunDown<>0
		BEGIN
			SET @strErrorDescribe=N'��Ǹ����Ҫ��ֵ���û��˺�ʹ���˰�ȫ�رչ��ܣ��������¿�ͨ����ܼ���ʹ�á�'
			RETURN 3
		END

		SET @OrderID=null
		SET @ShareID=@strShareID
		SET @Currency=@strCurrency
		SET @OrderAmount=@strPayAmount
		SET @OperUserID=@strOperUserID

		-- �����ظ�
		IF EXISTS(SELECT SerialID FROM ShareDetailInfo(NOLOCK) WHERE ThirdOrderID=@strThirdOrderID) 
		BEGIN
			SET @strErrorDescribe=N'�˶����ѷ��͹���Ϸ�ҡ�'
			RETURN 0
		END
	END
		

	-- ���һ���
	--SELECT @Rate=StatusValue FROM RYAccountsDBLink.RYAccountsDB.dbo.SystemStatusInfo WHERE StatusName='RateCurrency'
	--IF @Rate=0 OR @Rate IS NULL
	--	SET @Rate=1

	-- ���Ҳ�ѯ
	DECLARE @BeforeCurrency DECIMAL(18,2)
	SELECT @BeforeCurrency=Currency FROM UserCurrencyInfo WHERE UserID=@UserID
	IF @BeforeCurrency IS NULL
		SET @BeforeCurrency=0

	-- ��ֵ����	
	--SET @Currency = @PayAmount*@Rate
	SET @PresentCurrency=@Currency

	-- ��ѯAPP��Ʒ��Ϣ
	SELECT @ProductID=ProductID,@Price=Price,@AttachCurrency=AttachCurrency FROM GlobalAppInfo(NOLOCK) WHERE TagID =0 AND Price=@strPayAmount
	IF @ProductID IS NULL
	BEGIN
		SET @strErrorDescribe=N'��Ǹ����Ʒ��Ϣ�����ڡ�'
		RETURN 3
	END

	-- ��������
	IF @AttachCurrency<>0
	BEGIN
		IF NOT EXISTS (SELECT OrderID FROM ShareDetailInfo(NOLOCK) WHERE UserID=@UserID AND DATEDIFF(d,ApplyDate,GETDATE())=0)
		BEGIN
			SET @PresentCurrency=@Currency+@AttachCurrency
		END
	END
	
	UPDATE UserCurrencyInfo SET Currency=Currency+@PresentCurrency WHERE UserID=@UserID
	IF @@ROWCOUNT=0
	BEGIN
		INSERT UserCurrencyInfo(UserID,Currency) VALUES(@UserID,@PresentCurrency)
	END
	
	-- ������¼
	IF @OrderID IS NULL
	BEGIN
		INSERT INTO ShareDetailInfo(
		OperUserID,ShareID,UserID,GameID,Accounts,ThirdOrderID,OrderAmount,PayAmount,
		Currency,BeforeCurrency,IPAddress)
		VALUES(
		@OperUserID,@StrShareID,@UserID,@GameID,@Accounts,@strThirdOrderID,@OrderAmount,@strPayAmount,
		@PresentCurrency,@BeforeCurrency,@strClientIP)
	END
	ELSE
	BEGIN
		INSERT INTO ShareDetailInfo(
			OperUserID,ShareID,UserID,GameID,Accounts,OrderID,ThirdOrderID,OrderAmount,DiscountScale,PayAmount,
			Currency,BeforeCurrency,IPAddress)
		VALUES(
			@OperUserID,@StrShareID,@UserID,@GameID,@Accounts,@OrderID,@strThirdOrderID,@OrderAmount,@DiscountScale,@strPayAmount,
			@PresentCurrency,@BeforeCurrency,@strClientIP)

		-- ���¶���״̬
		UPDATE OnLineOrder SET OrderStatus=2,Currency=@PresentCurrency,PayAmount=@strPayAmount
		WHERE OrderID=@OrderID
	END
	

	--------------------------------------------------------------------------------
	-- �ƹ�ϵͳ&����ϵͳ
	DECLARE @SpreaderID INT	
	SELECT @SpreaderID=SpreaderID FROM RYAccountsDBLink.RYAccountsDB.dbo.AccountsInfo
	WHERE UserID = @UserID
	IF @SpreaderID<>0
	BEGIN
		-- �������ҵĻ���
		DECLARE @GoldRate INT
		SELECT @GoldRate=StatusValue FROM RYAccountsDBLink.RYAccountsDB.dbo.SystemStatusInfo WHERE StatusName='RateGold'
		IF @GoldRate=0 OR @GoldRate IS NULL
			SET @GoldRate=1

		-- ����ϵͳ
		DECLARE @AgentUserID INT
		DECLARE @AgentType INT
		DECLARE @AgentScale DECIMAL(18,3)
		DECLARE @PayScore BIGINT
		DECLARE @AgentScore BIGINT
		DECLARE @AgentDateID INT	
		SELECT @AgentUserID=UserID,@AgentType=AgentType,@AgentScale=AgentScale FROM RYAccountsDBLink.RYAccountsDB.dbo.AccountsAgent WHERE UserID=@SpreaderID AND Nullity=0
		IF @AgentUserID IS NOT NULL
		BEGIN
			IF @AgentType=1 -- ��ֵ�ֳ�
			BEGIN
				-- ��ֵ��Ҽ���
				SET @PayScore=@Currency*@GoldRate
				SET @AgentScore=@PayScore*@AgentScale
				SET @AgentDateID=CAST(CAST(GETDATE() AS FLOAT) AS INT)	
				-- �����ֳɼ�¼
				INSERT INTO RecordAgentInfo(DateID,UserID,AgentScale,TypeID,PayScore,Score,ChildrenID,CollectIP) VALUES(@AgentDateID,@AgentUserID,@AgentScale,1,@PayScore,@AgentScore,@UserID,@strClientIP)
				-- ������ͳ��
				UPDATE StreamAgentPayInfo SET PayAmount=PayAmount+@strPayAmount,Currency=Currency+@Currency,PayScore=PayScore+@PayScore,LastCollectDate=GETDATE() WHERE DateID=@AgentDateID AND UserID=@AgentUserID
				IF @@ROWCOUNT=0
				BEGIN
					INSERT INTO StreamAgentPayInfo(DateID,UserID,PayAmount,Currency,PayScore) VALUES(@AgentDateID,@AgentUserID,@strPayAmount,@Currency,@PayScore)
				END
			END
		END
		ELSE
		BEGIN
			DECLARE @SpreadRate DECIMAL(18,2)
			DECLARE @GrantScore BIGINT
			DECLARE @Note NVARCHAR(512)
			-- �ƹ�ֳ�
			SELECT @SpreadRate=FillGrantRate FROM GlobalSpreadInfo
			IF @SpreadRate IS NULL
			BEGIN
				SET @SpreadRate=0.1
			END
			
			SET @GrantScore = @Currency*@GoldRate*@SpreadRate
			SET @Note = N'��ֵ'+LTRIM(STR(@strPayAmount))+'Ԫ'
			INSERT INTO RecordSpreadInfo(UserID,Score,TypeID,ChildrenID,CollectNote)
			VALUES(@SpreaderID,@GrantScore,3,@UserID,@Note)		
		END		
	END

	-- ��¼��־
	DECLARE @DateID INT
	SET @DateID=CAST(CAST(GETDATE() AS FLOAT) AS INT)

	UPDATE StreamShareInfo
	SET ShareTotals=ShareTotals+1
	WHERE DateID=@DateID AND ShareID=@ShareID

	IF @@ROWCOUNT=0
	BEGIN
		INSERT StreamShareInfo(DateID,ShareID,ShareTotals)
		VALUES (@DateID,@ShareID,1)
	END	 
	
END 
RETURN 0
GO
