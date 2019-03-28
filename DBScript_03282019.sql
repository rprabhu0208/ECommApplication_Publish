USE [ECommApplication]
GO
/****** Object:  StoredProcedure [dbo].[INSERT_ProductImages]    Script Date: 03/27/2019 15:49:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[INSERT_ProductImages] 
	-- Add the parameters for the stored procedure here
	 @ProductID int, 
	 @xmlProducts XML = null
AS
BEGIN
	 SET NOCOUNT ON;

  IF ((@xmlProducts IS NOT NULL)
    AND (@xmlProducts.exist('//ArrayOfProductImage') <> 0))
  BEGIN
    IF OBJECT_ID('tempdb..#tTemp1') IS NOT NULL
      DROP TABLE #tTemp1;
	   
	  
    CREATE TABLE #tTemp1 (
		ProductImageID int,
      IsActive		bit,
      [Priority]		bit,
      Caption           VARCHAR(100),
      ProductImagePath             VARCHAR(100),
        ProductID       int,
    ) 
    INSERT INTO #tTemp1
   
   SELECT 
   
		prd.value('(ProductImageID)[1]', 'int'),
        prd.value('(IsActive)[1]', 'bit'),
        prd.value('(Priority)[1]', 'int'),
        prd.value('(Caption)[1]', 'nvarchar(100)'), 
         prd.value('(productImagePath)[1]', 'nvarchar(100)'),
         @ProductID
        FROM @xmlProducts.nodes('//ArrayOfProductImage//ProductImage') AS xmlProducts (prd)
	;
		
	 DELETE FROM ProductImage where ProductId = @ProductID

	--INSERT  INTO ProductImage () 
	INSERT INTO  ProductImage (ProductID,ImagePath,Caption,IsActive,[Priority])
	 SELECT ProductID, ProductImagePath,Caption, IsActive,[Priority] FROM #tTemp1 
	
	
	 -- SELECT * FROM #tTemp1    
	  
	 -- begin
		--merge ProductImage as p
		--using #tTemp1 as t
		--on (p.ProductImageID = t.ProductImageID and p.ProductID = t.ProductID)
		--when not matched by target 
		--then insert (Caption,IsActive, [Priority], ImagePath,ProductID) 
		--values (t.Caption,t.IsActive, t.[Priority], t.ProductImagePath,ProductID) 
		--when matched 
		--then update set 
		--p.Caption = t.Caption ,
		--p.IsActive = t.IsActive, 
		--p.[Priority]= t.[Priority], 
		--p.ImagePath = t.ProductImagePath,
		--p.ProductID  = t.ProductID
		--WHEN NOT MATCHED  BY SOURCE THEN 
		--DELETE   ;
		
		-- AND EXISTS(SELECT 1 FROM dbo.Vals iVals WHERE target.LeftId = iVals.LeftId) THEN
	  --end
	       
    IF OBJECT_ID('tempdb..#tTemp1') IS NOT NULL
      DROP TABLE #tTemp1;
	  --select * from ProductImage
  END

END
-----------------------------------

USE [ECommApplication]
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertUpdateProduct]    Script Date: 03/27/2019 15:49:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_InsertUpdateProduct] 
 
	@SubCategoryID INT
	,@ProductID int
	,@ProductName NVARCHAR(100)  
	,@IsActive BIT 
	,@DisplayAtHomePage bit
	,@ProductDescription nvarchar(500)
	,@ProductSize nvarchar(50)
	,@ProductWeight nvarchar(50)
	,@BasePrice decimal(18,2)
	,@GST decimal(18,2)
	,@ShippingCharges decimal(18,2)
	,@ServiceTax decimal(18,2)
	,@FinalPrice decimal (18,2)
	,@xmlProducts xml = null
AS
BEGIN
DECLARE @intErrorCode	INT
			,@intProducId	INT
	SET NOCOUNT ON; 
	BEGIN TRAN Product
	IF EXISTS (
			SELECT *
			FROM Product with (nolock)
			WHERE ProductID = @ProductID
			)
	BEGIN 
		UPDATE [dbo].Product
		SET
		SubCategoryID= @SubCategoryID 
		 ,ProductName =@ProductName 
		,IsActive = @IsActive
		,ProductDescription =@ProductDescription
		,ProductSize = @ProductSize
		,ProductWeight = @ProductWeight
		,BasePrice =@BasePrice
		,ShippingCharges = @ShippingCharges
		,GST =@GST
		,ServiceTax =@ServiceTax
		,FinalPrice =@FinalPrice
		,DisplayAtHomePage =@DisplayAtHomePage
		WHERE ProductID = @ProductID
		
		 SELECT @intProducId = @ProductID 
	END
	ELSE
	BEGIN
		INSERT INTO [dbo].Product (
			 SubCategoryID
			 ,ProductName 
		,IsActive 
		,ProductDescription 
		,ProductSize 
		,ProductWeight 
		,BasePrice 
		,ShippingCharges 
		,GST 
		,ServiceTax 
		,FinalPrice 
		,DisplayAtHomePage 
			)
		VALUES (
		@SubCategoryID
			 ,@ProductName 
		,@IsActive 
		,@ProductDescription 
		,@ProductSize 
		,@ProductWeight 
		,@BasePrice 
		,@ShippingCharges 
		,@GST 
		,@ServiceTax 
		,@FinalPrice 
		,@DisplayAtHomePage 
			)
			
		SELECT @intProducId = @@IDENTITY
		
		
	END
	 EXEC INSERT_ProductImages @intProducId
                                                ,@xmlProducts
                                               
	SELECT @intErrorCode = @@ERROR
		IF (@intErrorCode <> 0) GOTO PROBLEM
		COMMIT TRAN
		PROBLEM:
		IF (@intErrorCode <> 0) 
		BEGIN
				PRINT 'Unexpected error occurred!'
		ROLLBACK TRAN
		END	
		
		return @intProducId 
		--IF(@intProducId >0)
		--BEGIN
		--		return @intProducId  
		--END
		--ELSE
		--BEGIN
		--		return @intProducId 
		--END
	
	
END
