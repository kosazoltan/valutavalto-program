object BIZONYLATDISP: TBIZONYLATDISP
  Left = 201
  Top = -50
  BorderStyle = bsNone
  Caption = 'BIZONYLATDISP'
  ClientHeight = 749
  ClientWidth = 1067
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object blokkfejpanel: TPanel
    Left = 4
    Top = 4
    Width = 333
    Height = 33
    Caption = 'Blokk fejek'
    Color = 4210752
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object BLOKKFEJRACS: TDBGrid
    Left = 4
    Top = 40
    Width = 334
    Height = 473
    Cursor = crHandPoint
    Color = 4210752
    DataSource = FEJSOURCE
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnCellClick = BLOKKFEJRACSCellClick
    OnDblClick = BLOKKFEJRACSDblClick
    OnKeyUp = BLOKKFEJRACSKeyUp
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'BIZONYLATSZAM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'BIZONYLAT'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 77
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'DATUM'
        Title.Alignment = taCenter
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'IDO'
        Title.Alignment = taCenter
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 72
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'FORINTERTEK'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'BLOKK (FT)'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 92
        Visible = True
      end>
  end
  object BLOKKTETELRACS: TDBGrid
    Left = 340
    Top = 40
    Width = 282
    Height = 153
    Color = 4210752
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'BANKJEGY'
        Title.Alignment = taCenter
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'VALUTA'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 51
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ARFOLYAM'
        Title.Alignment = taCenter
        Title.Caption = #193'RFOLYAM'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'FORINTERTEK'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'FORINT'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end>
  end
  object NAPTAR: TCalendar
    Left = 340
    Top = 264
    Width = 282
    Height = 209
    Cursor = crHandPoint
    Color = clBtnShadow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    StartOfWeek = 0
    TabOrder = 2
    OnChange = NAPTARChange
    OnDblClick = DatumKiertekeles
  end
  object Panel10: TPanel
    Left = 624
    Top = 4
    Width = 381
    Height = 573
    Color = 4210752
    TabOrder = 3
    object Image1: TImage
      Left = 8
      Top = 320
      Width = 385
      Height = 249
      Picture.Data = {
        0A544A504547496D616765A41A0000FFD8FFE000104A46494600010100000100
        010000FFDB008400090607131312151212131616151517171818171719171817
        181816151817171817171A1D2820181A251B171621312125292B2E2E2E171F33
        38332D37282D2E2B010A0A0A0E0D0E1B10101B2F2520252F2D2D2D2D2D2D2D2D
        2D2D2D2D2E2D2D2D2D2D2D2D2D2D2D352D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D
        2D2D2D2D2D2D2D2D2DFFC000110800B7011303012200021101031101FFC4001B
        00000203010101000000000000000000000103000204050607FFC40041100001
        03020402070605020405050000000100021103210412315141610513718191A1
        F02252B1C1D1E1061415324262F1237292A2246382B2D207333473C2FFC4001A
        010002030101000000000000000000000001020003040506FFC4003011000202
        0102050204050501000000000000010211031221041331415122617181A1C114
        233291B1054262D1F015FFDA000C03010002110311003F00E5328D33FC8CA2FC
        1B750EB2C61A9B469CDA617A569AFEE3CAC64A5D605CD52DB35EB650E933204F
        D166AB85BD8A5D2A526C96A1243A79632A47A07F489CB02C551BD20FB409ED2B
        981857428E1A5B981BACCE3146E52948D94B1D504E7333A7254ABD31975BCACC
        E6B84CAE755A20946308B7B92739456C4757F6DCE103305D0C363886C113B19D
        1677D310045C2BB28C8E0AC934D14C20D31CDC692E198C094EC486921C1D0382
        C2EA31B25B69BB81429761ADAD8DD431794D8A7D4C64AC34691E5AAEB32A367D
        A0241F47B124921E326702B53B920A53EA12202F58EC352A976B44AF3FD35483
        1C037BE15D8B26A7A4CF9A1A13918595DE2C09EC4A056BA0F130D46B5023F771
        5A632517D0C72C6E6AEECC6AD4DB262611CA41D0AB5417B88299C994C62BAB36
        51C3D322F33BCACB568C1D642A056CC916A4FA9749E392E82DD1BA10B4380D92
        D8DE4994B62B962DE90B5D0C0B8022782553A039A6B28C68AAC934D51A306294
        1D9D6EB9368FB56980B9CC309DF9E8D382C4E1E0E9A9F93757735A21656D73BA
        5BF1408BA43AAC20A1E42E4743F3892F734EA25739CFE688A851E583986A15C0
        74B5913A243E96B075E08079ED5A03C29544BB3264773516DFCC0DD442DF826C
        799015A4EEAC1A8E55BF6388AC632A088324A566D82651A5263446AD38313296
        A365DAF269BEC2DB51C34242D74B1EE022495980472A2E317D5091CB923D18DA
        D8A73B8954A759C14CAADD59D7828A3141797249DD8D38856762CC5A25232A30
        82C7119E7C859D88251A75CED297088746853E855D0AB9D34EDB37D17C9BD96E
        A81B122E570DCF3B9503CEE554F0B7DCD0B8C4B668EAE1FA5CB46581F7593A46
        B875F8AC6421953C70A4ED154F8A94A3A5A2A2CB49C408016784615B28A6518F
        2CA3B236D1CA413374FA34333807B6C7D6AB98256BA788701ACFC9533835D0D9
        8B3296D243F1383A42C334F0D9606D1E61761B543DB19AF1B2E69A241323C12E
        39BE8D8D97146D34BF62D4B07B944E1B645808D53057810029294868C215D041
        A642209509566B820C78FB16CC0EAA8E027644A4B8A5487721A1D1C502F078A4
        66557394D20D65B3ABB5EB317281C8E91759B9AF441E6B175AAE2A24711D4CDA
        E03820B2F5AA25D2C3AD14C4D46E5005E3942CD28CA042D2956C73E73D4ECBD3
        3C6744C15370960A88D5854DAE858BB6E3BAB61DD06F7F92AC7251A0FAB29B50
        149DD9ADF55BA81AEAAECAD925B136B09001EFE01646DADC0EA37ED4CC5468DB
        0234327293B1F7498B70279AC79A7A1D3E8CE8608F323A9754CC0313FF001240
        FD8E6DA0C80440CB3C4DF5E6BA3D598CD10263BD79CE87A44D621B62D7BE26C0
        72DC70137E165EB6857A8016B985B98105AF1C4E86347091A8F7ACB061E32508
        B8BDD9B7370519BD5D11CF78E7BF91845ACDCC2E6F43F491A950D23EE9267958
        93CE47C53F1F887F5CE631C1DA19E4403C38F085B71FF508C9255B9827FD3DA6
        DA7B23A151FA6964927B902812BA315473273B61461573731E4875BFD43C4222
        D7B0CEFF00245A077257583DE1E214EB87BC3C42815F01D50B62C0F6AAB6FA25
        8A8371E2AEC74E97ECFB2574874EDF41AC306D64D158A5B285432431C63FA4FD
        138E12A02D191DED0916E1CFDDD3430AB94A1DDA2F8EBEC981A792055BF2CFF7
        4F924D6392EEB77FD12EA8F91FD4BB3FD8B141A56638C67BC157F3D4FDE08B22
        91B09433058FF50A7EF79153F50A7EF791FA252C566DCC3655C8DD962FD4A9EE
        7C103D2B4F9F82031B0D06EC7C50EA1BB1F1593F56A7FD5FE945BD2D4B8F59DC
        C9FF00F410B64AF6368A6CF7510C6ECB0FEAD4F6A9FE81FF00921FABD3F76A7F
        A47FE485869F83A195BB20B07EAACF72A7FA47D544035EC79F763EACD9FE1F0B
        0553D2353DF2AF88021B4DA6C3F76925C75D3825E36831848CC27BCFC963C1C4
        C9AB9BEA6A9E08F48C43FA954F7CA1FA854F7DDE2901A1598C1C56DD5B599F44
        7A50DFCFD4F7DDE254ABD20FFDA1CE2789CC6072E69783A59CC59A41833C3C93
        69E1E7F9345E2E758F5C775972E7C73496AAB2FC78DC656A366AE8FC49232BB3
        FF0049692729B5CB7573794F1EE54C5D5325A487447B46D607B2C24DA16EC260
        BAB06A3C83A406920EB12490081622DAA5E2DF45C7FC4A6E6BA09CCD76F27420
        823EEB9B93238FA53B46EC704FD554C5E0B10D0F2E10498120489683304EBA6B
        C9762A631CED6096B7D9824FEDBC01A10399D02E3D5C2B7286532086CDCC0700
        E92439BA7391B9D204E86CD1820E674FF183A00E6B471FECB2D2BBB34AF060C2
        FB35AB543A5C11A4B9F0481D92E31D8B754B52CE4FEEBC41E3A715CBC5384BCC
        C0791173A684F79047FD21175673EC0499B0124C6C38E8B5F090939EC67CFA54
        1D87F36761E7F543F3679271C2061FF108264CB1B7361A133633C06C52DC18EB
        0696B8C9179698D46E0E802EBFE2617EDE7B1CCFC33ABA29F99721F9876E950A
        2D1655A50DFCC3B728FE61DB949011852C9486F5CEDCF8A19CF3540D3E885614
        CFA210B0520E6533A190EC8152C9459CE2753E6549414128590B4A20AA8055DA
        C76C7CD06C290655811B7C5560A201D8A5B191691EEF99FAA12365513B152FB1
        F02858CA8BE6E5E411CDDBE5F45500EDE4A5FD4A163522F3DBE4A66EDF2FA2A4
        FABA93EAE80C5FACEDF2512C93EA144016737A39B9C83668025CE326D0787171
        8317DF45D4AD529871653A60C18CEE92E3B721C410024E0E90A9529968029D32
        E711CE7F9584FED637B02D5531548025AC20CE85DFB86F6BF7705C2E626F73A3
        25B6C647B6FA768FB2B36A532088870E1ACAE8D2C3B09045C1124365AE13E2B9
        98EA6CBE5CC1CDBF2236E661689711374E2FA1447145F52B8CAA5A65A7FF0070
        41E265AD02F1C3E2568C1D36D8B581EE02EE3B6C00B0E2B0E21C1F4DA5A64826
        675EFF005C56CE85AE5CF2D6C0631A4B9C7801A39DDF000E6B237EA722EC71EB
        675B0F2C24D5009734FB247EDD482608249DA557A431C6A80DA3866B458666B4
        F0B59CE3A199D78A4FE6B3E67539FF0031BB8F01C8760547BCBA25D61209ECD6
        122C8D6ECB13EC8A51C2D4A7ED3A05BDE106386BBC92B9F5718E6BC89916CDA4
        F389DA616FC4F49E4643181AD9893049EC9D3BB92E4BDC5CE8049CE74E2E2489
        B09B97011BA314DEEC6DEC5E27101CFD4068E310389048035B9B09D575A9749B
        6953735ACF69D0339D4890EF6761ECAE561700331EB09D865361A89F11E057A3
        ADD2752A35B483802DF6498BEBED13E3A01B98956EB69520C927D4E560B1AF19
        9C0DCEB613A183F2EF2ACEAE78EBF0DD7473527025CD01CD312016663A80E03E
        3E3748AB4D927DA78235901DF085A3869637915DD9933EBD2E8C24299569A986
        02E1E08DC7CE744BEAC7BCBBB169AD8E636D3A62B2953294F1487BC88A5CD1A1
        7588CA5485A3A947A8E6A5035A33654613CD22965B1A8408A565211CAAC02B4F
        24036503510DE4AC0F2443B979A5614C1914C8AE0FA9FB221BCBCC203A171E82
        89A35F4504A30B089098D16D14CA806C565BA046A213A0290A06C41780A26969
        DFD78A2A00B52C5B1A4BE27DA888F79A786E3B3805CEEACBCBA070173A89D2DE
        2B3979CAE910E96EBCADF3F35B3A2C5B3389F6627C45873E3D80AE0C2A3B9D79
        783774561A9E1E9F5D8873C4BA1997F9471260DB5D9331F4A8620E6A3532B8C4
        670D826C2C40F63C3BC26622A758C0D7C983A1D0CF0B2E0E3290A44B208BC81A
        F814BA9B96C235467345ED0F6410F0E008B0D4C6A6D7275E69EFA5D5B720324C
        1711C5C664CF100587693C53B0CCA955CEC82453682E26272C8D0F122663B522
        BE1C9D204738BEC0765FB8A6D377B84DFD1EE1D5E469D2731EDD0CF69D392BE3
        F12DA61AC6893603EA7B4DFD149E8AA058D32002F20F60026609E69588033126
        E4DED78DA3B9532772A2C4B6B3286B9F98BA499B760E1E6B6618067B42EE1BE8
        2C07D80F0D13F058704B8C6F11AD80249E51F1572DF61EE8FDB66DAD711A6FDB
        A2B25B7A40BA5982BE24F58E75A486803877028639CE158B81FEA9DEC27D7359
        2AF1E727C1746B65710E1A5879653E70AEC70726A1EC24E4A2ACB61EBE68246F
        DF2753BA6D3787DC6B1047316B795BB51652104445BE0A818403016FC7C3CA0F
        557430CF3466ABC845904FACD32612E0ECBA51DD5A30BD9D329DEA0ED5751405
        8038EE8E73B94442002200879DCA21E7755850200A2C5C880AA0A92804B81E82
        B73FB0540F566BC7A095850C68B29907A855279A19F8256588BF8A0E77AD149E
        1F351BEB74062A06EAC07822DD397AE4893E2804A1681E8A39071BFAF2506BDB
        CD47123640258536F11E4544013B37C94500717A42BCBDCE16CE49802D27F710
        39993C96EE8CC39826FA899D34E27C962AD820D7C17021BA96FF002136904D81
        B593710C0000C30489CA092C3788179075DFB970366769A3B2CA0E2D39434B88
        3194924F7B8013CED6B715E7AAF59D710F0730D666446BDDD8B7F46D476971C0
        6DB15BB1751ED9A8D782D032DFDAF64FEE038EDFD92EAD2F615A5D84F45623A8
        6BC8FE6D9E22674D2F024AE6E27FC43ADCCC419EE4865473CE506D7EEDBB754A
        1EC907883F4F0D1346352D4C568D54B14FA661E090788D7EFBADA5AD7DC19D79
        477705D018565468302E3E22E96FC086CC0D481A7000FD5745628E396BAB462E
        7CB22D1D1946B72378CBA674D34803B8AB360B0B00B974C72FEEAF826E60ECC6
        F9A3FD202B369035728E0CF8B87D078A4C5C32941CA6F7916711C4E992C705B4
        56E71B1CC01D940E04F6C953086191FD43E5F45D3C4D068AB4C1E21DE42DE655
        E9745DCCEF31CAC78F7AB5C74E5B8F9AFA15F335625ABC5FD403BB440316F184
        089C28E4BA69C6ECE3BC92AAA673BAA0AA690DD74CE1C7240E1C6C9B520731FB
        9CDEAB9AB0A6775D01871EA42B8C28DBE2A6A40E6B399D5A1D4AEA8C28D91FCA
        043522735F8672BA943AA2BB0DC28E488C10E486A44E64BC1C4348A3D495DD38
        21C91FD3F921A907992F0704513B2B0A05775BD1C361E0AE30236F5DA95C90F1
        C8DF6388DC293C479CA9F963C87AD6EBBC302234F9FF00645B821C04F6CA4734
        5AA4FC1E7CD072B753B9F8C2F4030035FA21FA78DBD7821AD0DA9F83CFBA9AA0
        A7DBF0F92F45FA7855FC876F821AE21529783CF0611DBEBC531AC278C2F40304
        38FAF3081E8EDC5FB07D50D683AA5E0E1064F1F10A2EE1C20D8792886B44D4FC
        1E27A92D0F2F1941CC41D1CE9F678EA04CAC544100106276E066FE63E09D5B12
        6A38F39EC1A69DDE2AAC659CD8BFEE1E1ED7941FFA5710EFB474709D22C2D2D7
        8F6C36011A18D330F984CE90C50C81B00B5FA91C0EB7DAE46BB15C9C2B6486C5
        CDA7889B1F25D9C47469EB594AC0B331989CCD8907CA23B50D37D046D27B99BF
        0F60DBD76530416F39046F3E1DE133A43A3C53A9FB411339795FE4BD0742605B
        1D641922C788DC1EF57C6F454BF3458803BC98F985A5E27C94FB98FF00131E73
        8DF6FA9CDE82690D2C7490D323B1D27BAE1755B4869949F5D89D84E8E0C24FF4
        81DE267E49F52880D27604E9B09E2B7638B8E3DCE7E5CF1964F49C6E8D005390
        C997BC8303DF2070E4B536934DF2807727ED08743E1668D3326ED0620C5EFF00
        35BD984DDD3E49E11F4A173674B24BE2CE27495202AD074830F2DD047B404798
        5B9CC26C353B1FBA5F4DE100EAB7EB99AAEA3B0E635F24B15EA634F2AD107F1F
        E4E71A6788F9FCD56761FD96E76109173E1FDD4A78670B5FBCFD938BCD465263
        51F051A7FA481DFE50B7F51FF51E64FD14CA7833FDC7453711E48B30960379EE
        39BEA8168DBB815B5F45CEE023D76A51A278016EDF9C21A98D170154E993A103
        6DFE29CCC33B63DA74B23D5BBED6F2D93A9B1C38CF7A0E6C6B88B142F6F92390
        D86FA84E7338C81CC4FD555C06BAF6DFE2A6A62DC445563A6D0AC0387068E729
        AE27818E11015C5731607CD0D4C29C405B6D421D59F95BE2AED7B89998EE31E6
        8E471BFB3E050B614E2BB94148F17767D94D357CED10A3B0DD9E053194CC00E1
        6E5EAC95B1D4A3E45B9E46B69EF4A6E22FC7BBFB2D4DA607033DFF0004453034
        1AF3503AE28CDD65EC7BFEA22CAAE040D4FCBEEB5F52ED80EF3F34031FCBCFEA
        80399132031F78B22D04E9A0EDFA2D2CA4EE31E09FD4CEE1115E68AEE6013EF4
        77851740D21B9F108A9427E263E4F94D7A0E612F8B07653BC96C811C82D987C0
        BCD375483669703B8E1F085AB0D83CF8524898AEE8766D1A1CD69991A65062E3
        5E365EAFA3F0ACA349D4DCE04CB0913312F6921D232B75E06E093A2E533D21E2
        B1B86CA03982D620F9FAED5BF0B481739E66E6013A4011F195DBC454A7D416E5
        6C37335AE1FB8E4040246D6FF6F79C5D197A6D0C33ECDCC02336AE1241FE52B4
        E278DCBC2FB997329A879FF42D94CB45A63BFB535B55FC1C7BE4FC42DD4308F3
        FC8780FB279E899FE439DBE4BA292E87225955DB39871957707B955D8EA90418
        88336E479AEB3BA2470701DD3F359F1DD181949EECE4E5638C44680A92AD2CAB
        1E7C6F2456DD51CCC0E35EDA4C00B400C68BF62D0DE937FBCDF0FBA7F4774335
        D46992E3258C31DAD053BF441724D809274802F25345545099388C4F238ADDD9
        CCC7E39EE0C272FB35186D3B9DCAE853E9271BE59ECCD2B274DE05B498C807DA
        AAC1AF695D86E180E00248AF54BE4366CD0E4C1D79FE448E931EE541DDF7459D
        2CCFEA1DA3E89DD5347F16A8037DD1E0159463E741F60B31CC768FF97C55E46B
        F00834EC077221CA08E6BB17A6FE6AD9F925870DC29083229075FE31CCC7C894
        C6D2ECEF458D28B6912907D5EE023D7DD0148706A6F50EF7A3B931B4772A035F
        F9190D1E5DCADD54708D96D14C6EAC698B5D0A02CABC99BAA3E8A1D52D42937D
        6E8E56FAFAA9A5839D1EE64EA86DF39562D16B95A086ED6ED425BB22A2CADF11
        0467EAC6E51CBCD3C386C14CE11D0C55C5C05868DFC42B359EAC9A1E116BC704
        1C58EB89C62C535053EFEF4D0F0A661EA10D2C6E7C194C9CBCC289D2CE313D8A
        214C3CD87B7EE8F9B6070D41ED1D65634C30904325AD19DC5DFBC82E20E5DF82
        F58CE8561A7D5F58E7B6A999CEE3ECB5A44020D84B858593703F872975633090
        F6303DA74243449EFB4F62DB82C0B69B9CD6486B00681320177B4E036FE0B043
        16EACF45938ADA4E2FA1E77A63A16950C3D47B0443081724093789D352BAD47A
        3DAD6801A3E493F8DAD847F32C1E2E0BB669AD78D28C9D2F072B89CB965862F5
        3DDCBEC73FAA3B2AB9ABA258ABD4F25A35A4AD9C9962C93749D9CFC8B374A37F
        C1A9FE477C1759CC6C13234E73DD02E565E92A1346A4820F56EB18912D9837D5
        2CB34251693EC598782CF8B342538B4B52EDEE62E88BE1E8FF00F553FF00B02D
        697D034A70D47FC8D1E023E4B5BA8ECAC8CD5228CF827CD95797FC9E7BF16DB0
        F9BDD7B4FC5768AE6FE2DA1FF095278653FEE0B6E0DB9A9D374FEE634F8B4149
        19A537F235E4E1A72E171AF0E5F5A6589096E84EEA3B1034B92B75A32AE126BB
        999ED94B34D6A73390487CEDF1514907933450534DA408E2A83371576B1CA392
        272A6696D42AE1FCD67141C9D4E89E3050D68ADE09792E1C8CA994055210E621
        170B365C1452A540E439C875C0647DC7221B2962A8038A736A5A52F3D0FF00F9
        D93C90532A0A476469D49E09A132C96532E1B4ECD8A14F9239392B978F4554B8
        73475311C62BB903110DEC55940142D93645B2FA9E5C902D5277472F77D14B0D
        5F4041E4A2B47A9FB28858741E67A2FA5DEC607540F6E600876B4E4890321D07
        642F47D098A156975920B9CE7178136713A5F80103B953A4704C2C6332C1739A
        D68316F64871EE6C9EE5B701D1ECA4086489D64FC973B1A9465EC7AFE2251963
        E94DFD8E07E3DFFE3D36FBF5E934F7E63F25E8CB5703F1FB630CD7FB95A93CF6
        027EABD296ABE2F7663CB0BC51F9FD846450353F2A9953EA31F2C490975A9666
        B86ED23C410B56550350B54149A699C2FC28D9C3307BA5E3FDEE23C885D7EAD7
        23F091FF000EB37DDAEF1FED61FAAEEE55212F4A2CE2A1F9F25EE70FF15D09C2
        56FF0028F270287E1CA59B0B40FF00CA679340F92774ABB3E06AB8EBD53A6CE6
        DDA2F01D7024714AFC2B5C0C0517E52E86C43449B3CB0DBCD053577DA8B658A6
        B068ADD4EBE86D386D926BD1CA0B9D60D0493C0002492BAE5A160E9EE8FEBB0F
        569071697B08046B3C3BA75B8B2772465845B924CCE30D37F82A9C3DEF3E16EF
        202D1840EA54181E73398D6365E436746C971D5DF13A6AB73A983E8A1AEFA05C
        5C777D374BE5FF002394288D95B2EC174BAA0AB913D94372F073CB09E0A94A99
        22E20DA45E39C1204F6ADFD6377080AECF792F7EA3AD5A7F4FCCC9D42870EB69
        0142D47D254DE4310C30DFB1586186EB5C2807253616F27933F50156AB406971
        04E5049812600931BE8B6068848C5E143D859300F1E60833E212CA7516D0F8F1
        6A9A537B3EBF0282982245F64451BA66128E4635A346B40F011DC9A028B23A12
        5823A8C868F777850D2BAD45BCD54B13730ADF0EBB233F54A06109E29A1D529C
        C07205002FA772AC6D3E0B416230A6B1F91D8CE183D1513F2F3410D6C3C85E0E
        2FE16E907E25D3535A0D0C3B17BF5776C3634E2BD2A8A2CD0E87A1E252D6792F
        FD43E9060C33E8DCB9D938587B408BEE60AF45D198ACD4293FDF6533FEA6B7EA
        A28A45EEC7CB8A2B140DA0A2028A27B3038A24230A28A58BA51E7BF09C93893F
        F3DDFF006B7EA17A00A28A43F497714BF399CDE97C386E1AB86D81A754C0B092
        D7126DCEEB95F83680ABD1B4D8620E7D448B557116ED85144AA2AABD8B549A83
        977D48F4B4810003161AEF0AEE0A289EB63137D4A57C387B4B5DA1B1FB7922D6
        1E254512C56EC79FE85F3FB04B14EAD451394D2B1670E361E4A0A0068028A256
        3AD98AFCBBF50E836D391988D2E8D0C206B4340000D000001C80160A28952EE3
        4E5292A6F62FD528588289CA1C510B54CAA2883615144CAA428A21D88D24C084
        22A2814930415145140A8A24219515112248F1DD35D31876577B1D5AB348225A
        C8CA0C0D25A51514589E4767661863A51FFFD9}
      Stretch = True
    end
    object Shape1: TShape
      Left = 48
      Top = 24
      Width = 305
      Height = 113
      Brush.Color = 3289650
      Pen.Color = clWhite
      Pen.Width = 3
    end
    object Label1: TLabel
      Left = 88
      Top = 32
      Width = 232
      Height = 29
      Caption = 'PARTNER P'#201'NZT'#193'R'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label6: TLabel
      Left = 72
      Top = 96
      Width = 258
      Height = 29
      Caption = 'BANK MEGNEVEZ'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 176
      Top = 64
      Width = 53
      Height = 22
      Caption = 'VAGY'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label7: TLabel
      Left = 168
      Top = 144
      Width = 61
      Height = 25
      Caption = 'SZ'#193'MA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label8: TLabel
      Left = 128
      Top = 232
      Width = 156
      Height = 24
      Caption = 'MEGNEVEZ'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object PARTNERSZAMPANEL: TPanel
      Left = 104
      Top = 176
      Width = 185
      Height = 41
      BevelOuter = bvNone
      Color = 4210752
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -29
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object PARTNERNEVPANEL: TPanel
      Left = 16
      Top = 264
      Width = 369
      Height = 41
      BevelOuter = bvNone
      Color = 4210752
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
  end
  object Panel4: TPanel
    Left = 340
    Top = 4
    Width = 282
    Height = 33
    Caption = 'Blokkt'#233'telek'
    Color = 4210752
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object DATUMPANEL: TPanel
    Left = 340
    Top = 194
    Width = 282
    Height = 36
    Caption = '2013 szeptember 23'
    Color = 5263440
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 6
  end
  object ELOHOGOMB: TPanel
    Left = 340
    Top = 232
    Width = 139
    Height = 25
    Cursor = crHandPoint
    Caption = 'El'#246'z'#337' h'#243'nap'
    Color = 7368816
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
    OnClick = ELOHOGOMBClick
  end
  object KOVHOGOMB: TPanel
    Left = 483
    Top = 232
    Width = 139
    Height = 25
    Cursor = crHandPoint
    Caption = 'K'#246'vetkez'#337' h'#243
    Color = 7368816
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 8
    OnClick = KOVHOGOMBClick
  end
  object Panel2: TPanel
    Left = 4
    Top = 724
    Width = 1005
    Height = 38
    Caption = 'Panel2'
    Color = clBlack
    TabOrder = 9
  end
  object Panel43: TPanel
    Left = 340
    Top = 584
    Width = 671
    Height = 135
    Color = 5263440
    TabOrder = 10
    object STORNOGOMB: TPanel
      Tag = 4
      Left = 8
      Top = 40
      Width = 217
      Height = 23
      Cursor = crHandPoint
      Caption = 'STORNO BIZONYLATOK'
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = ATVETGOMBClick
    end
    object SUMBIZGOMB: TPanel
      Tag = 1
      Left = 8
      Top = 8
      Width = 217
      Height = 23
      Cursor = crHandPoint
      Caption = 'AZ '#214'SSZES BIZONYLAT'
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = ATVETGOMBClick
    end
    object STORNOZOTTGOMB: TPanel
      Tag = 5
      Left = 232
      Top = 40
      Width = 233
      Height = 23
      Cursor = crHandPoint
      Caption = 'STORNOZOTT BIZONYLATOK'
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = ATVETGOMBClick
    end
    object ATVETGOMB: TPanel
      Tag = 2
      Left = 232
      Top = 8
      Width = 233
      Height = 23
      Cursor = crHandPoint
      Caption = #193'TV'#201'TELI BIZONYLATOK'
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = ATVETGOMBClick
    end
    object TCIM3PANEL: TPanel
      Left = 232
      Top = 72
      Width = 233
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
    object TCIM2PANEL: TPanel
      Left = 8
      Top = 72
      Width = 217
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
    object ATADGOMB: TPanel
      Tag = 3
      Left = 472
      Top = 8
      Width = 193
      Height = 23
      Cursor = crHandPoint
      Caption = #193'TAD'#193'SI BIZONYLATOK'
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
      OnClick = ATVETGOMBClick
    end
    object TAP2PANEL: TPanel
      Left = 472
      Top = 40
      Width = 193
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
    end
    object TAP3PANEL: TPanel
      Left = 472
      Top = 72
      Width = 193
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
    object TNEV4PANEL: TPanel
      Tag = 4
      Left = 8
      Top = 104
      Width = 217
      Height = 23
      Cursor = crNo
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 9
    end
    object REPRINTGOMB: TPanel
      Left = 232
      Top = 104
      Width = 233
      Height = 23
      Cursor = crHandPoint
      Caption = 'Bizonylat '#250'jranyomtat'#225'sa'
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 10
      OnClick = Ujranyomtatas
    end
    object VISSZAGOMB: TBitBtn
      Left = 472
      Top = 104
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'Vissza a f'#337'men'#369're'
      DragCursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 11
      OnClick = VISSZAGOMBClick
    end
  end
  object BIZONYLATTIPUSPANEL: TPanel
    Left = 338
    Top = 480
    Width = 282
    Height = 49
    Color = 4210752
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 11
  end
  object STORNOPANEL: TPanel
    Left = 338
    Top = 536
    Width = 282
    Height = 41
    Color = clBlack
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -24
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 12
  end
  object SZUROPANEL: TPanel
    Left = -1800
    Top = 128
    Width = 425
    Height = 537
    Color = 2105376
    TabOrder = 13
    object Shape19: TShape
      Left = 1
      Top = 1
      Width = 423
      Height = 535
      Align = alClient
      Brush.Color = 2105376
      Pen.Color = clRed
      Pen.Width = 4
    end
    object Label3: TLabel
      Left = 24
      Top = 24
      Width = 371
      Height = 36
      Caption = 'BIZONYLATOK SZ'#368'R'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object GroupBox1: TGroupBox
      Left = 32
      Top = 72
      Width = 353
      Height = 401
      TabOrder = 0
      object RR1: TRadioButton
        Tag = 1
        Left = 16
        Top = 32
        Width = 217
        Height = 25
        Caption = 'Sz'#369'r'#233's kikapcsolva'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 0
      end
      object RR2: TRadioButton
        Tag = 2
        Left = 16
        Top = 72
        Width = 297
        Height = 25
        Caption = 'Csak '#252'gyfeles bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 1
      end
      object RR3: TRadioButton
        Tag = 3
        Left = 16
        Top = 120
        Width = 281
        Height = 25
        Caption = 'Csak v'#233'teli bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
      end
      object RR4: TRadioButton
        Tag = 4
        Left = 16
        Top = 168
        Width = 257
        Height = 25
        Caption = 'Csak elad'#225'si bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
      end
      object RR5: TRadioButton
        Tag = 5
        Left = 16
        Top = 216
        Width = 321
        Height = 25
        Caption = 'Csak konverzi'#243's bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 4
      end
      object RR6: TRadioButton
        Tag = 6
        Left = 16
        Top = 256
        Width = 321
        Height = 25
        Caption = 'Csak p'#233'nz-'#225'tad'#225'si bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 5
      end
      object RR7: TRadioButton
        Tag = 7
        Left = 16
        Top = 304
        Width = 313
        Height = 25
        Caption = 'Csak p'#233'nz '#225'tv'#233'teli bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 6
      end
      object RR8: TRadioButton
        Tag = 8
        Left = 16
        Top = 352
        Width = 297
        Height = 25
        Caption = 'Csak storn'#243'zott bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 7
      end
    end
    object BitBtn1: TBitBtn
      Left = 128
      Top = 496
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'Vissza'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = BitBtn1Click
    end
  end
  object COPYPANEL: TPanel
    Left = -1658
    Top = 304
    Width = 425
    Height = 113
    BevelOuter = bvNone
    TabOrder = 14
    object Shape20: TShape
      Left = 0
      Top = 0
      Width = 425
      Height = 113
      Align = alClient
      Brush.Color = 4539717
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label4: TLabel
      Left = 24
      Top = 24
      Width = 387
      Height = 29
      Caption = 'K'#201'REM AZ '#218'JRANYOMTAT'#193'S INDOK'#193'T !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -24
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 112
      Top = 64
      Width = 84
      Height = 24
      Caption = 'INDOK ='
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object INDOKEDIT: TEdit
      Left = 203
      Top = 64
      Width = 153
      Height = 32
      BorderStyle = bsNone
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      MaxLength = 10
      ParentFont = False
      TabOrder = 0
      Text = 'ASDFRTGHZX'
      OnExit = INDOKEDITExit
      OnKeyDown = INDOKEDITKeyDown
    end
  end
  object LAKCIMCSIK: TBitBtn
    Left = -1900
    Top = 184
    Width = 497
    Height = 33
    Cursor = crHandPoint
    TabOrder = 15
  end
  object Panel1: TPanel
    Left = 4
    Top = 552
    Width = 332
    Height = 169
    Color = 3289650
    TabOrder = 16
    object Image2: TImage
      Left = 1
      Top = 1
      Width = 330
      Height = 167
      Align = alClient
      Picture.Data = {
        0A544A504547496D61676587220000FFD8FFE000104A46494600010100000100
        010000FFDB008400090607131212151313131516151515161717181716181615
        15171517171717181717181F2820181A251B171721312125292B2E2E2E171F33
        38332D37282D2E2B010A0A0A0E0D0E1A10101A35251E252D2D2D2D2D2D2D2D2D
        2F2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D2D
        2D2D2D2D2D2D2D2D2DFFC000110800A8012C03012200021101031101FFC4001B
        00000203010101000000000000000000000304000102050607FFC4003B100002
        0103020305060504020202030000010211000321123104415113226171910532
        81A1B1F0061442C1E12352D1F1627215824392073363FFC4001A010003010101
        010000000000000000000001020300040605FFC4002C11000202020201020503
        05010000000000000102110312132131415104052271A16191F032B1C1D1E123
        FFDA000C03010002110311003F00F01A6A69A368A852BDD1E77603A6A69A2E9A
        BD34C6D8169AAD346D3534D146D814548A2E8A9A689B603150A5182D4D14C8DB
        01D1534D1B4D4D34C6D8015AAD34709534560EC2FA6A69A3E8A9A2983B80D353
        453012AF45106E2FA2AF4531A2AFB3AC0DC5F454D14CF67562DD1B06E2DA2AC5
        BA67B3AD0B7441C82BD9D5F674D0B757D9D0179057B3ABECE9AECEA767581C82
        DD9D4ECE9AECEAFB3A00E414D157D9D35D9D4D140DC82BD9D568A6BB3A9A281B
        9054A557674D68A8528079053B3ACF674D94ACE8A036E5C54D35E64FB7AEC60A
        49E7A4F2F8C7CABA5C0FB7ADB2FF0053BADE0254E37F0F2AF8F8BE67826EAEBE
        FD17C9F05960AEAFEC75345568A9638A475D6AC34F33B44759DA8A904020820E
        C41906BBE39232F0CE57B47CA05A6A69A3E9ABD354B17701A2A76747D357A68D
        83717D1534533A2A68A64CDB8B68A9A299D153B3A366DC5B454D14CF6753B3A6
        B36E2DA2AFB3A645BAB16E883716ECEAF45322DD5F6746C1C82C2DD58B74C8B7
        5A16EB58BC82C12AC5BA645BAD68AD62BC82A2DD58B74D0B75AECEB5839057B3
        ABECE9AECEAFB3AD62F20AF6757D9D35D9D5F6742C1C829D9D4ECE9BECAA7675
        AC1C829D9D4D14DF6755D9D0B0F20A76753B3A6FB3AC94A56CDC82BA2ABB3A68
        A564A50B194C54A560A53652B25695B1D4CF9DB5B1A8B0287BC7BA63FD1F8506
        3398FBE9565FFE3F5AC123CABC09EC07AFD9EE83A742E9996392379524039335
        7C3FB4AEDA50A8FDD064081F1F314D0E2B862A0325E6222476AAAB300120E827
        97872E99BE0EC58BD7422AE856D80D776E40932B900B1DA20ED46192507716D7
        D8128465D3EC7386FC49B7696F1892A4E3C7491D7C6BA56BDB161813AF4C7F70
        2091C88EB3E140E27F06DE9FE8F0FC4B281BDCB0D6836FDE5371D4B1CEC140F0
        A42DFE14B8D74DA0C8580123577C4CC77535EA246400768EB5DF8BE6F9A2BB77
        F738F27CB3149F4ABEC7A3B2EAC0329041E6322880578CE2782BFC2312494236
        EF2F78062849499395710460A991BC31C27E22BC3DE02E026040D267181A4797
        2E75F4F0FCE31B5FFA2A7FBAFF0067065F95E45FD0EFF0CF59157140E0F8C5B8
        24482375610CBE63F7A601AFAD0C919A528BB47CB9C6507525D900AB8AB5135A
        D262631E554D84ECCC55E9AB06AE994853216B416AEAC536C0B282D5E8AD0AD0
        A362D99095612B42B55B615B3212B412B42B55AC56CC04AD68AD8ABA1B0AD98D
        157D9D6C55D0D85B663B3A9A28952286C6B60F454D144AA26B6C6EC195AA2B5B
        26B04D2EC324CC915922B4CD5834AE43D33245648AB26B24D0721D1445608AB2
        6B05A91C8756735FFF00C43ED31FA2D1F2BA2BD7FE19FC09C6F0F64DB36802CE
        C4B04B5DA1503BA0B973CE48DFCABEBDC3F10C090D88C6673E2399F9530FC62E
        DAE3CBF915E0DBD976CF7317AF847C47DB5F86C16097EC686BA484378800F7BB
        A8AD6C28670CC70209998804D7A3F627E1D1C3816AD5ABB6D7F51169ADB3F4D5
        7718C4464EC6249AFA2B71883993E20C0C7339FDAA7E7C6F071F01F5A9BD5F56
        3ECFCD1F37E2D9866C70D71802435C6385D0CA0AB9604C100810B077C6F5CEE0
        ED5EB6C6E9736DBB13D9AA58EEDBD4CA5821BD992349C28D8E398FAA5EF6C402
        4C003E9F18AF25ED5FC5B6AE18EC45D2A24165000EBA644FD28A705D0AF667CB
        2E70BA19B88BD71F896ED585C2C7B36552560826E91D27BAD018FF0068AE4970
        CC1B429613DA00D705CB614086174CDB6015409103530264135DFF00C4DEDD7B
        EAB6596D8B68C00408A0281C84C91E75E51789695EF666277C18C03C87855AEC
        84B2289D2E1F8B4B864B25BBAAB2BDB5B08840C06ED6720F418DE35629A5E325
        CA1ECF00B165BD6CDB6064CA966040036582633B0A4B85613DE5049DCE9C9DF7
        35D0B5C3DB9F717FFA8AFA7F058F245A9639D7E9E9FB1F33E2FE2F14AD4F1DFE
        BFF489C5A112181F8D6C710BFDC3D6985451B01F0AD055E95E8965F73E23947D
        1316FCCAF515A1C4AF5A6020FB1562D53F289B47D85FF32BD6A7E697AD322D0A
        B16FC68F2A06D0F615FCE0FB357F9E1D3E74D76553B3ADCC6DA1EC0ACF14A480
        4859204B32AA89EAC4C0153F3CB3821BC558302391041D8D316C104112083208
        DC115454F434BCB2DBCF5F9FEE6DB1578EFEE047183C7E55A1C5AF8D1349AA21
        A9F9909F47B7E4A1C5AF5AD7E717F9FB355DEFB153BDE1E95B9902A3EC4FCE2F
        5FA56BF36BD7E95993E1F2AB93D07A56E689AA3EC6BF36BD6A7E6875FA56093F
        DA3D2A89FF008AFA56E58992410F143C3D6ABF343ECD0BFF0055F4A91FF15F4A
        DC910D208789F2F5AC9E27CBD68640FEC5F4AA207F62FA50E443248D9E23CAB2
        6FF956748FEC1E958207F62FA50DD0C92086F79560DEA11D3FD8BE9586D3FD8B
        E94AE68751414DEF2A19BDE2286553FB17D287D9A7F62D2B9A291844FB9CB0C0
        C4CE7DC1B78C9ABB7C42C91A893CE0608FFB19A498CFBC67CB03E54BF11ED244
        C627A02B3F7E75E07B67B4E91D4B97A47F6F96FEA735C9F6BFB4BB31DD12DE26
        23C735C7E2FDA975CE0951D032E7CCEFE95CC733BE7CCACD3280361AE3BDB2B1
        06E49F1999F21815E5F88E3E78804088524C1DE4C0DF14FF00136158F89FFAE6
        B88BC377EE9E8C0788500E7076C7AD5F1E34FA673E5C8E3DA39BED024DEF8961
        99CEFE54A9E08CF2DE6BB3C5582A664C831F118237A77B39008D88919AEFC7F0
        90AECF919BE2E57D0970767D47DF2A68AF856ED8D27C3E9E55B561F7E95F471C
        A30548F95924E52B60029AB04D1E31F21566204F3C7DF5AA7312B0526B727C2A
        CA0E9FE2A693D3EB47985A44D7E23D2B4A4D5CF87DF3A907A51E615A35A8F856
        83D6013CBE95651BEB47984690456A2AD0155BA1E5CBAD185B6E86B72A12491B
        0B57D9D602B0C451141E947949B45767546D7851A3919AB3889FBF851E5058B1
        B3E1593669B8FB81358E7BD37207662C6D563B3F1A702889FBFF00551946F22B
        6E1D9891B5E3546D788A74D8FE7A7AF5FF0035836874FBFBF1A3B8CA62452B25
        69C36FCFE4287D9FDFFBA3B0EA62845648FB9A68DAA1B5BFBDE858EA42C45608
        A64DB3D31E79A1B2F41F1A1651485CD0CD32C9E15991D2B594523DD717C4B361
        5C0E44C8F2C677A56DD903F57CE93B5C4AF57F97FBA23712A3F4DC3F2FAD78CB
        3DAD04BA46D23D6805475141B978B6C87D6B275F4F59A64CD40AE60838C1FE2B
        93C1DC9E26FAAFBBD9CC0FEE17614FA335752F5A7381BFD3CEB8B6AEF65C65A2
        D8B6CCD6AE39F7556E956127F4F789CF49D855F1B21997819EC81522670C7940
        D31A46FE3B1CC15DC6CA70CE4774CC9988C0F1115D5EC08D4A49F11901412244
        1DB53007A00044C9252E3F850C3036D87F037F866BB1653E564C5D864B4C7650
        27064CF946D9A2DAE1DA0CC08389313E436A07B2F8D3A821F780804132C3249C
        721E15D13B8993041E4679415E6361BF4C014794E596116160913AA0662713E1
        8D8F9FCEA9ED3C755E446013B11E07C0C9A25EB52BCF2D300C1260E7A4C12624
        48EB45B36A6E3660AAE570012310CDB201E38F3A6E5212C42A19F4E71E99F123
        723CAB604C16689D88F7601DFEE22BA372C00A018D5A661880A0EEC35641F31E
        8281651582C6F83110679B0D3323CD7F8659484B1FE8085A026673CE677ADAA7
        C739CCFC29816F05ED8904E9EE1D27AE63119D881345B76D258609188F75FD07
        D6996539E50606D912394FDFC68A1703C7C47A1A97352100F4F758463C7A9AAF
        777C6FD63C7909F4A6590E796361604FD71CFA0F0AD04F1F3FF1594711333880
        66498E9D2B6D10D88C03E74CA649C59936F1E750A7851D32478AF9FA56036F8C
        8F1FB8147712982283C85619314D32C7C72320C7DF5A190220919DBAD36E14D8
        009D467A9991FE6B247967D3E14709E5D2ABE07EFC3F7A3B85480153F7B50A08
        E98F08FDE9A7B7D77F5FBF8560A88FF7F234CA63A90001A76813CC4FCAB2FCE0
        FCFEE28C40143D307ECD36E3A68AB9E3FCFC6B13F01E7FB6F5A2DE7EBFBD61B7
        E7F7E547719199E93F1AA6FF00556CA686B1BC8F28FB14771D14DEBF0A1CFDEC
        28A41992409CC608A03924CE23CFE93BD1E428916E60498CED9FF142267947DF
        855398FF005FBD5283CC2FC4914771D47A3D2FFE48F241E83E5583ED0BA7947C
        04D35DAA0E9E9E13D6A0E217A7A721FB578F47B913EDEF1E9F3A1C5C399FAC7F
        14F3717D050C5D9F909FBFB346CC23711BA9F03FCD79DFC596C843FF0025E437
        D2EA7E5935EAEE49C7DFF15E73F139EE82DB430F0EF2E3A74AAE397D44B2AFA4
        EBD886E1F877826387B273CC8B6B82DE19E63AD5681139C7A91B0F0911914AFE
        1BB93C15BDBBA5ED803910C58EFB986524F88C4534A738C893B1989822679692
        3113E5354DA9D1CB3859C9F6870457220119C40E867D629CF64F19DA4063DF53
        EE89939C34993E99CD3BC4A02BA8679804138E5CB9F9570F8CB0548B8B820CEF
        39E6A44647853ED672CA147A03654111A40191962D008D62018CF8E041C1A1F1
        CA7B27CE925C691AA200E6CC63560C6098C6D9A07B3F89176D93A4020F7963F5
        4103912D2769F1E94F1B0ABDE602403E18006A0AAC06A270209380C70715B723
        2C62B71D4BA8EF17B8A06A0011DA0952B26421D87BA7799CD65028B6FA9674BA
        82C41051F304C7BA2272A064411B538F648D4584B280D7174870248606277C8C
        723B355718E143DD251CDE01343860E570410E4CAB0806248C53299270461D88
        850AD724021826BB8ADCF538D459647BC1668C4927BE408F74CEA0D89F020F9F
        CA89C3DA3AAD0512C154AB16FEAAE40D1AC00AD0331BCE289C5DFB41F5396EC8
        E2586A51708E4CB0D6DB9CFED4FB9CD2C6BD8AB1DF1D9AB05B89FA598C9F0527
        541D8C7F358900C66D96E4EC3413E640D33470FAD192EFF5963BAEA07696F9A9
        04E76DC55597B8D68FBB75418EF40713D4120820FCF96F2CA64658AC19B70097
        465653323623A7C3C28966D12BAC02C3A8203FA0C11F1ADD868955D08674E825
        81CF2EF0001F5A86351074A9E8C46FE640F1C53A99096240DB79DD8F81F96F9A
        B462048C91E33E107A7950AF3297133B6208F5123F7159FCBC91064CCF794863
        E12041A75320F1060DD71390098F9F5ABD227A1239CC1F039C1F1A5AD5F0C4F7
        4C7238207C4098A655F48CEA18F1F51FC53EE4F428BC8D4013C8ED20F8F5F8D5
        3AFC0F43CAB4F0565B3E3033E71154EFB09F2DF50FBF4A65315C0CE99E9F2C78
        F8D60E7CFAFF009EBF1AA05B51DA47311EA401068A5CC6AC48F220FAE47D28EE
        0D055CFDC63F9ACC759A3C023DD39E91F63E028771548F7A7A83008F5DE9B60D
        0BB20E5F7E60F3AC6D91F203E9442B1E23EF9F2A04743F38FE28EC511772089C
        CF96FE9B5019091B6DBC7EF1B7C689247F19F51427B91CE23D3E98A3B1588355
        27FDD618C6E6B772E4E4FAF5F8D0D98ED8F4FDB7A3B154506E9FE3F7A1CB741F
        7E7564FDF3F9FF008A199E94762891EB6797F123F7FE2B25C6FB7DFF00AA82CC
        F5FA7C37C9CC54EC0671CB967C7FC5797B3DA836200EB9C67F615AD5CA3C7F89
        1CA89D98C73DFD3E1E5F4AD85DC0CFEDF1ACD86803B6436E4088F4DBF9AE07E2
        204DB91FDC4FC9ABD0B91A0B83EECE7AE7607C6B8FF8800EC67A440927EF73F3
        A684BEA42645F4B39FF84E3B0BBBC8BAA4F4EF234107AC83F2AE9212588124EA
        85883074E95C36006008910264CC45717F0E5CD08E1BFF00999540D505E01D5A
        4130224662790224D75B5C9ECE4779D4C11005C9825088ED779233CCF3C5A7E5
        9CE97439C3DEE5105F2AB071048724A88DC743E741E26D0130756AE5020EFCC9
        1ABE044552DDD88CE9401D4B100B3953201DF1240E983B663F16AC45B8249F75
        55601CE4EDEB38F1A0A44E5138B751B87B82EA42B419F754B29C75907C2BAA9C
        54A9BB6F4F7A66533DC00EC1A5C8C189898A72E7024AB161A7C4FBE46705BF48
        81B0EB5E7EE86B2758116CE1F2648681813AA63C8114D7641AAE99DCB5C63B2B
        35C60BAC02A0774DC71962E546399891B8DE2A76C585F2F73FAAAAAEE55958E3
        48D0AB232A08122248327352C80D67559816D80235004EA273DD20CF4E46A719
        ECF916CB856D44B5D1307538C4C99180391F3C60A64A686AEDE1AD58AEAB9754
        302EAE97018C68BB6FDC247220E714B58F6AEB900876412A1725C8E598170F58
        11BD1E49728A552DF6055219C3A14B64A81A895995C111B55FB2385EC8917155
        EE03DA231011DF4EECAC8C53583D44F59E6CA5D1194503E0B8837876DA7B208C
        034A8FE993B69FF8EF9EA73D68DED0655741743A8600AF1164CDBF0254820F2D
        9BD2A708A7880D72D916EFA826EDBBC616EAF32A63BC0CEC7D690BFECDB967BC
        A6E5A0C35767ACBDB651CD48C3AF830F3269D34FD48CA35DB5FE4E9FB6B87704
        2DEBA0B2006D5F41DC2BBAF68A32BE6350A64DF7BA00E2D2182F72FA4323F425
        93DE5FA73A9C0AD8B962DE9EF16D52A47F4D5B73A1BDEB67AA831FF0A5FD8F7D
        41B96EC5E1267558BC000F18251B0A1C7591FB53264A516DB34650AA3056520C
        18041119D25498E5576B8356CD876959907DE5E78820B0F2DA8456E1B9FD3428
        C37B6C3BDA8EDEF086C6DE54D5BE296EB2DAB882DDD9C301A1A46D86881F18FA
        536E438FA026EAB7FF00B13BDB13A8A991CC1E7E5577C6850172A79344A9FDFC
        C56F8DBA9ABB2BCA5586D711A09F302738E73E62AB84054F72E0B8B9EEB8EF7C
        339F304D36E4A58C170FC604C1250F5E47E11B5317AC4ACAAA38EB6C90CA77CA
        EF56D7A098736F9E87EFDB27E231F3AE75EBC667405E8F6C851F11B1A65211C2
        BA1C6E24E23BDE0C276FA50EF5F59D9909F1907E07714BB71538BA35F4B8251F
        D577F8F4A3592C526D5C3717728F1AC47300FBC3CB3E14FB09A12E5B232B91CC
        448A0DD681A86DCE24C7A64503F34B320B5B607703BBF238A2DEBE430660AE0F
        35307CE46453290BC664B4E4104781123CF1FE284D767799EBD7CFF9ABBCCB32
        A089DA627D621A85760E66239A8DBFEC27E94DB19448EA0EF1F188F9FEC68570
        11CB1F123E18C7AD412460AB7CBEB585F1EEFCC7A8FE68D8EA24040DB1F7FF00
        1FDE80C7A18F2DBD2B6CD1B807C460FA8C1F8834266F113F007E5834532A9196
        3D401E53F4A1B79FCCFF008AB763B47A60FA1A147D9041F951D8AA47ADFCC7DF
        58DF31FCE6A9AF9FAFDC1DF6FA52D9CEFBCEDCCFEFFCD5636DA3FDFC79D79C3D
        AD0CADFCCF4181323319ACADC235732C76DE3C71B8C4D0DC62794E3ACD532CC1
        5E591CF3FE2858682F10D012D888DCF33DD88F999A43F1118B7906237E4331BF
        ED4DF1AF2C8D11048F1338FAC503DA96835A230D8077DC8381931D68C5F6849A
        E8F31C3BAE8B574E8235B2B06EF0EE0461A8098B73A41D89F2DFBDDBC82DD9AB
        A944B8A88C4190640D20C689D58C88538DC5724AC7097ADAA8D697CB1529AB50
        740134B2E48EEED98DCE0D33C37161AC2F7C1736DE67BAAB703105096D9E341D
        380099EF4C1EA97673447D6C77A181258B5D0480ACECE225581D17429538DC11
        B08C36BC485505321E20C46073207BB993D2922970860A9DFEF235B9D2E13018
        D92C0F777124663FE42B7C2433368C3113A482A0955020488598981D48E55360
        687F88BE18B850DA7A81EF7C790C7957278AE1A574E98D4674812DF7D6BA1C15
        D2A8D7092C1A22062498248F0CD034E754B90D3277827963E3F3A2991946CE6F
        0D7DAC1ECE34AEA90C7BDA0919071B7957A50152D2ABE19E598ECE1449240DCF
        C7E1D6BCC711C207D4DDF0B0727227C078F8D5FB2FDA82D95B375EE0FD2A489C
        1C85659D8188FF0014FE48B47A3FCC8BBD9AAA8EEA92C4295627BD015670D007
        38322AAC71F60D8B0B78320B8CECC0A6A5282575395128646186707314E25EB4
        8B171A4E59DD554EB29916C632C27DE8CFC290E3DCB8BF3716E495054A9016DB
        1264FBAD13A44E4F5DEB2649C7DD0D70C6DDCB42C25F1AADDC66D0643A23A804
        45DC5C40567489F781E54AF1769B87BA6D98EC08572AD3A431DDAD410536C853
        A4C6C6287C67056DAEA888716E5C4E0268D24AB8120053B1063E540F60F1D8B9
        C3BEA0EA9A9038172D300D264731A762B3B53465EE4E50EBE919E0ED359BC1B8
        7B98BEA196581170A9CA8060336F82267CC517DB0DC3BDF52C8D69E60DCB7DD2
        1B6EFDB260EF98D27E948FE2436EFDBB20DC4B2D04766D840D3FA5CE141C46A8
        F3A1F0DED67B56FF002FC6276911A1AE2EAB96E3DD1AC4315E99E78C5327EA4D
        C2D74CED5CE0F8AB2E025C0EA040912AC3908991067C4668FC2FB5DEEB763C4A
        AE3005D1A5D7C6DDD8CF2AE62B8E2D3470F7CF6993D9B1EF3673A18C6AEBA771
        FF002A6782E03887B4D62F2B160355A2CA43295DC09E67A4CCED44938B5D337C
        6F0EB6C9B77548427BAE06A03FF5E5F0F952CC9738701C69BB658E1D35113B64
        990A7FE2629BF63F146FFF0045DC4CE987F483B67C489F2355ED4B1C4700C480
        4DB6C3158B96C8DA186E3E23E26993F426E09F6805ABE9C444900F285124F489
        C9F0F1AC711AECA98208D8CAC8C728391E828B72D59BE355AD05B9AC853CF623
        2450BFF246D8ECEE9D56CE34DC218AFF00D5D4C8F2A653252C663D9F7D0ECDA5
        BFB58774FF00D7FC456AFF00F4CC8943E11A73BC0FD851B88E021250AB236412
        4181F1123E19A4FF00F22C1745C42CA3008CC780273F0A64C4943D097388FD37
        4289D98011F12285F952300023F4B290CBF18A60DDD49DC02E2FF690CAC3E269
        0D0A0CAEA4F007511F4FAD3A909A06ED14A94705586C40907CF9FD697B3788C6
        A07A1983E59A3DC790083DA6D3813E932281C45A42356DD4447F914CA40D7D02
        B26242F9C47EDFE28576DDB6CEB2A7C563E6286806E8CC0F4C3034277CE7BA7C
        8E93E60FD68D85459A2847356F1073FB5058F223F6F96D5BB96E33F4DBE558ED
        246F3F0FDC51D8740CC758FA7A1ACCF954763B448F9FC39D08378B0F5A365523
        D3B01B1CFC3C3C7E1F3A21118DA77CD04DCE87D07D6B4CE37CC099E9D3FCD7C0
        3D91BBAD18F4106B0EB0B1BB1F5AB0FCF03FB710685C35EFEA4666249DB07A4C
        D008CDB3A908789DA3A102B99C7592A8A4E4ED8E67967909E747F685CD371620
        0333D49F38EB44E22F0B8A54931076DC1EBE34D17DA126AD1C0B686E5ABA8A83
        B44168101811A44AA341F782850A63395E955EC1208D2353AA91A96DB5C1DAC8
        63A5D10086192186C0676CF3F85E257F31DE4FE9DC0B69FF004B0D4E8D2064B4
        15063A6D4C7B2F525FD257FA649521B0B31A0107249060E398C78F63F0CE55E4
        EF7B4D833B972E6E31636D4CE94165886D17301909ECE0B46E6623216BFAAE17
        2C501075A98760C5762C6188D700100E073DAB7C7DC90E4AF79800AD03B362DA
        9D8F70429572996214EA3118905C2005E1F53EA70A1F23587C5CC03FA482BCC1
        06D8EB5241639ECFBC51E255575F64FDD1009D5960008883E3E747E2432BB299
        0BFA74C69D52008233133B75A53DA6755C2752A96B76CB12625DA18309DCE9F0
        9C1346E21D6E0560C415451006939C923991E06944681DC9263BC59544A93083
        4F30732723D4573F8FE141E7719880C0FE993E279E76F035DDF6922BDB57004B
        CCC49EE898C7EDE35CEE15352EE140DC0DCFF224D3C64465115F66FB44B06B7D
        A39BAA9EE112856409333072260729F2E9F1AEDA597BAED70067B807BE3986E7
        BEFE227909E6713C1B07D68DD9B2FBBDD927249339F0DC1ABB37DC5C0ACB68DD
        2E58B2B76648304C831BC4FC0E39D335EA89BAF53A6FC0F6219D8B4A6AB5A48E
        F84388D5FA80D4479450FD9365EC16742AEA356948986233037FEEC8C98F0C41
        72E5C7EF2151308C3218093260F74F7731FB4533C682A96CB5B21356BED532A7
        90F107DDCCCC1A17E82354732EFB47B7621EC5B667CF78152400333A86623A1C
        E6BBFECEE2EC35A165EDADC555C2BB7F52DEF847198F3EB5566D2332DD742D61
        8CDC23BD90324099520F311B79D7038EE12F2DC57043202343A806DBA9CCF420
        E3C88E469D1267507E1CE1EE5D1F96BB711C056547009322405B8304E76313E2
        698BBEDABFC2155BF2F6CE56E2483037047223A1F0AE57B4EEDFE10DB6B0FA96
        EA2B856C9B641234AB4C98207391304F3AEE5BF6F2DDB71C570E0ABCB38EF280
        DCDEDB6E098C8E7046626B377E50BAB8AF23BF88385B3C5584E36D7BE0C39B64
        2B98D9BA13D41A1FB2F8DFCCA685BC1AE288009D24F8156C83E523A75AE1705E
        D7E150BD93AD6C3C1F7B36D86CCA76208241077A5FDA5EC708E1D6F29B6D9471
        8C8E43C7C3E39DCBC7F57F62534EEEBEF41EF1BD66EC5CB60107DE50358F34C8
        3CEBB56FF2FC5A1D417B4DE5540240DE577F88915CDE03F12FFF000F1917ECEC
        1C66EDBE521F711D36A1F1DC08E1D83DBB84A1EF2B0DCAEEACBD7CB71EB476EF
        D89B82ABF2BF3FB14C6F70848527B33C889583E591F2AAE22F369ED6D360C4AB
        C303F1DF1D587C6BACFC51BD6E0F677247BC04309DC32823D457078BB86CCA94
        611D44671B1DC19EBF2A64C4717E812DF11A84E9456E7880C6391DA673593721
        8875D2DBF7802B9E840A53B7B71A816071B1CCF8C1C1F3A619D9D412DA97AA81
        23AC8811F2A6B15C0C369D5B8427A994DF93098F2ADF11C3DD400900A1D994AB
        29F239141BE580EF0D49FF0068C79138F3AC70FAB3D896DF284820FC27BDE934
        DB09A168B6BFB995BC4023F69AC5F2D19EF0EA3A788A969EDB92AFFD26EA04A7
        C41C8CD62E16B461848E446411D47F069948CE0CC59B9C9491D44E3D0D5BB47B
        CBF104C7CAB1C4709AFBD65949E930C3E077F84D093881EEDE46047EA43B1F10
        647D28EC3AC77FCECBB84F2323CFECD085F6FB22B41A7DD69F310450D9C8DD66
        B58CA3E8CF402F0E9E7938E9F4DAA25FE5023FDF854A95F1A8F5E52DD258E40F
        A9F84CC551BA64920C289C0DBFC54A95A8255CBA2E19E40C74FBE74B5DBA4120
        19004EAEA7A7FB3FC4A9452A048F1DC7EA371B724C98DCE3398F0AF53F886E7E
        6380E10E43AA1561938071AF248048904C9319F1952BB25E8CE48AF231ECE651
        C222B00506B563A809772DDE267BAA234F4EEB6276DD9721AE1D3DA685550B96
        61DAE6D80601220AB4038000313352A54E71D5BFE7B05768DDA858177BE8CED2
        F121EEE932148E6300C6D0474AABDD92AE8476D52C6710D05B07C940F8AED575
        296846038AF6A3ADB53125B18CF7700C8F1DBE15E87D9BC3ADD5C1D81619CCE4
        EE3C5AAEA52E454AC11568CFB5352AACA9965338D4368E471CFD2BCFF1962D3F
        74161BE7BDAB03949EA2A54AA63F073E44857D9F79751B72080D00647239009F
        1DA9DF60ADD256DF68CAC1CFEA20104119DD488F5D22AAA51974C0E3D1DE5F69
        5C22F0D211ED0685034EA8055C41C19938E7CBA572FD89C49BD6EE5B12A5096D
        0640C4482391DF39F1AAA943D192514C5859EDA10C3A1624216ECEEA9FFF009B
        9EEB0E5077E98147F6B59E2F8451D9976B7CE546271172D1903CF20F23D254A7
        F5A125D2B39D7C28B56F8816C28B8CE8C83F4B20124063250EAF304113D5FB97
        C5AB097AD1D569895B88DB0612543011062608827498A95299A0C1292F022AF6
        2FB4DAB9D95C13DCBA610E7F4DD02397EB03CEBD17B2F8466B6D62E02867500D
        B29E4C83683E152A5693684CB8A29F4738FB36FD9248EBB8234379F4A6F85F6C
        DC606DDD40C7A301AE0C6C798107E555528AFABC9CD25ADD1CFBBC5DAD452F5A
        0396A18D39E7434E18DA8B969C9427947A10706A54A79FD3DA1A11DA23566FA5
        C1DD73AB78D0089E92222917B50D8243748D27E1C8FA8A9528A2728D3A3572F8
        7216EAB07DA762639C1DE85ADEDE045C4E8723D08C55D4ADEA6A542CE6D3FBA4
        DB7E8720F936EBF19AA5E248C5C9E80E1BD6797C6A54A7A19C55A40388B3198C
        755DBD3950178B618907CC49A9528A1F1A525D9FFFD9}
      Stretch = True
    end
  end
  object BIZTIPUSPANEL: TPanel
    Left = 4
    Top = 516
    Width = 331
    Height = 33
    Caption = 'AZ '#214'SSZES BIZONYLAT'
    Color = clSkyBlue
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 17
  end
  object HAVIFEJTABLA: TIBTable
    Database = HAVIFEJDBASE
    Transaction = HAVIFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'BIZONYLATSZAM'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'TIPUS'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'DATUM'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'IDO'
        DataType = ftString
        Size = 8
      end
      item
        Name = 'FORINTERTEK'
        DataType = ftInteger
      end
      item
        Name = 'TETEL'
        DataType = ftSmallint
      end
      item
        Name = 'TRBPENZTAR'
        DataType = ftString
        Size = 3
      end
      item
        Name = 'TARSPENZTARKOD'
        DataType = ftString
        Size = 4
      end
      item
        Name = 'STORNO'
        DataType = ftSmallint
      end
      item
        Name = 'STORNOBIZONYLAT'
        DataType = ftString
        Size = 10
      end>
    IndexDefs = <
      item
        Name = 'XBF1303'
        Fields = 'DATUM'
      end>
    StoreDefs = True
    TableName = 'BF1805'
    Left = 16
    Top = 168
    object HAVIFEJTABLABIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Size = 10
    end
    object HAVIFEJTABLATIPUS: TIBStringField
      FieldName = 'TIPUS'
      Size = 1
    end
    object HAVIFEJTABLADATUM: TIBStringField
      FieldName = 'DATUM'
      Size = 10
    end
    object HAVIFEJTABLAIDO: TIBStringField
      FieldName = 'IDO'
      Size = 8
    end
    object HAVIFEJTABLAFORINTERTEK: TIntegerField
      FieldName = 'FORINTERTEK'
      DisplayFormat = '### ### ###'
    end
    object HAVIFEJTABLATETEL: TSmallintField
      FieldName = 'TETEL'
    end
    object HAVIFEJTABLATRBPENZTAR: TIBStringField
      FieldName = 'TRBPENZTAR'
      Size = 3
    end
    object HAVIFEJTABLATARSPENZTARKOD: TIBStringField
      FieldName = 'TARSPENZTARKOD'
      Size = 4
    end
    object HAVIFEJTABLASTORNO: TSmallintField
      FieldName = 'STORNO'
    end
    object HAVIFEJTABLASTORNOBIZONYLAT: TIBStringField
      FieldName = 'STORNOBIZONYLAT'
      Size = 10
    end
  end
  object HAVIFEJQUERY: TIBQuery
    Database = HAVIFEJDBASE
    Transaction = HAVIFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 56
    Top = 168
    object HAVIFEJQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'BF1805.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object HAVIFEJQUERYTIPUS: TIBStringField
      FieldName = 'TIPUS'
      Origin = 'BF1805.TIPUS'
      FixedChar = True
      Size = 1
    end
    object HAVIFEJQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'BF1805.DATUM'
      FixedChar = True
      Size = 10
    end
    object HAVIFEJQUERYIDO: TIBStringField
      FieldName = 'IDO'
      Origin = 'BF1805.IDO'
      FixedChar = True
      Size = 8
    end
    object HAVIFEJQUERYFORINTERTEK: TIntegerField
      FieldName = 'FORINTERTEK'
      Origin = 'BF1805.FORINTERTEK'
      DisplayFormat = '### ### ###'
    end
    object HAVIFEJQUERYTETEL: TSmallintField
      FieldName = 'TETEL'
      Origin = 'BF1805.TETEL'
    end
    object HAVIFEJQUERYTRBPENZTAR: TIBStringField
      FieldName = 'TRBPENZTAR'
      Origin = 'BF1805.TRBPENZTAR'
      FixedChar = True
      Size = 3
    end
    object HAVIFEJQUERYTARSPENZTARKOD: TIBStringField
      FieldName = 'TARSPENZTARKOD'
      Origin = 'BF1805.TARSPENZTARKOD'
      FixedChar = True
      Size = 4
    end
    object HAVIFEJQUERYSTORNO: TSmallintField
      FieldName = 'STORNO'
      Origin = 'BF1805.STORNO'
    end
    object HAVIFEJQUERYSTORNOBIZONYLAT: TIBStringField
      FieldName = 'STORNOBIZONYLAT'
      Origin = 'BF1805.STORNOBIZONYLAT'
      FixedChar = True
      Size = 10
    end
  end
  object HAVIFEJDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HAVIFEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 168
  end
  object HAVIFEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HAVIFEJDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 168
  end
  object BLOKKFEJSOURCE: TDataSource
    DataSet = HAVIFEJQUERY
    Left = 224
    Top = 152
  end
  object TETELQUERY: TIBQuery
    Database = TETELDBASE
    Transaction = TETELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 16
    Top = 128
  end
  object TETELDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TETELTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 128
  end
  object TETELTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TETELDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 128
  end
  object HAVITETELQUERY: TIBQuery
    Database = HAVITETELDBASE
    Transaction = HAVITETELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 16
    Top = 208
    object HAVITETELQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'BT1805.DATUM'
      FixedChar = True
      Size = 10
    end
    object HAVITETELQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'BT1805.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object HAVITETELQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'BT1805.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object HAVITETELQUERYARFOLYAM: TIntegerField
      FieldName = 'ARFOLYAM'
      Origin = 'BT1805.ARFOLYAM'
    end
    object HAVITETELQUERYBANKJEGY: TIntegerField
      FieldName = 'BANKJEGY'
      Origin = 'BT1805.BANKJEGY'
      DisplayFormat = '### ### ###'
    end
    object HAVITETELQUERYFORINTERTEK: TIntegerField
      FieldName = 'FORINTERTEK'
      Origin = 'BT1805.FORINTERTEK'
      DisplayFormat = '### ### ###'
    end
    object HAVITETELQUERYELOJEL: TIBStringField
      FieldName = 'ELOJEL'
      Origin = 'BT1805.ELOJEL'
      FixedChar = True
      Size = 1
    end
    object HAVITETELQUERYTORTRESZ: TIBStringField
      FieldName = 'TORTRESZ'
      Origin = 'BT1805.TORTRESZ'
      FixedChar = True
      Size = 4
    end
    object HAVITETELQUERYSTORNO: TSmallintField
      FieldName = 'STORNO'
      Origin = 'BT1805.STORNO'
    end
  end
  object HAVITETELDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HAVITETELTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 208
  end
  object HAVITETELTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HAVITETELDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 208
  end
  object BLOKKTETELSOURCE: TDataSource
    DataSet = HAVITETELQUERY
    Left = 264
    Top = 152
  end
  object FEJSOURCE: TDataSource
    DataSet = FEJQUERY
    Left = 224
    Top = 112
  end
  object TETELSOURCE: TDataSource
    DataSet = TETELQUERY
    Left = 264
    Top = 112
  end
  object FEJTABLA: TIBTable
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'BLOKKFEJ'
    Left = 112
    Top = 88
  end
  object FEJQUERY: TIBQuery
    Database = FEJDBASE
    Transaction = FEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM BLOKKFEJ')
    Left = 16
    Top = 88
    object FEJQUERYFORINTERTEK: TIntegerField
      FieldName = 'FORINTERTEK'
      Origin = 'BLOKKFEJ.FORINTERTEK'
      DisplayFormat = '### ### ###'
    end
    object FEJQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'BLOKKFEJ.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object FEJQUERYTIPUS: TIBStringField
      FieldName = 'TIPUS'
      Origin = 'BLOKKFEJ.TIPUS'
      FixedChar = True
      Size = 1
    end
    object FEJQUERYIDO: TIBStringField
      FieldName = 'IDO'
      Origin = 'BLOKKFEJ.IDO'
      FixedChar = True
      Size = 8
    end
    object FEJQUERYTETEL: TSmallintField
      FieldName = 'TETEL'
      Origin = 'BLOKKFEJ.TETEL'
    end
    object FEJQUERYTRBPENZTAR: TIBStringField
      FieldName = 'TRBPENZTAR'
      Origin = 'BLOKKFEJ.TRBPENZTAR'
      FixedChar = True
      Size = 3
    end
    object FEJQUERYTARSPENZTARKOD: TIBStringField
      FieldName = 'TARSPENZTARKOD'
      Origin = 'BLOKKFEJ.TARSPENZTARKOD'
      FixedChar = True
      Size = 4
    end
    object FEJQUERYSTORNO: TSmallintField
      FieldName = 'STORNO'
      Origin = 'BLOKKFEJ.STORNO'
    end
    object FEJQUERYSTORNOBIZONYLAT: TIBStringField
      FieldName = 'STORNOBIZONYLAT'
      Origin = 'BLOKKFEJ.STORNOBIZONYLAT'
      FixedChar = True
      Size = 10
    end
    object FEJQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'BLOKKFEJ.DATUM'
      FixedChar = True
      Size = 10
    end
  end
  object FEJDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = FEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 88
  end
  object FEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = FEJDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 88
  end
  object PENZTARQUERY: TIBQuery
    Database = PENZTARDBASE
    Transaction = PENZTARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 296
  end
  object PENZTARDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = PENZTARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 296
  end
  object PENZTARTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PENZTARDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 296
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 352
    Top = 80
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 384
    Top = 80
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 416
    Top = 80
  end
  object PENZSZALLQUERY: TIBQuery
    Database = PENZSZALLDBASE
    Transaction = PENZSZALLTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 336
  end
  object PENZSZALLDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PENZSZALLTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 336
  end
  object PENZSZALLTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PENZSZALLDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 336
  end
end
