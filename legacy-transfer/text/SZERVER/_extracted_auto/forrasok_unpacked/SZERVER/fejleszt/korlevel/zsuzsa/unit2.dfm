object superform: Tsuperform
  Left = 192
  Top = 114
  BorderStyle = bsNone
  ClientHeight = 621
  ClientWidth = 847
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 847
    Height = 621
    Align = alClient
    Brush.Color = 4539717
    Pen.Color = clWhite
    Pen.Width = 6
  end
  object Label1: TLabel
    Left = 152
    Top = 32
    Width = 577
    Height = 37
    Caption = 'K'#214'RLEVELEK SUPERVISORI FELADATAI'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object KISMENUPANEL: TPanel
    Left = 200
    Top = 104
    Width = 425
    Height = 233
    BevelWidth = 5
    Color = clWhite
    TabOrder = 0
    object KLDELETE: TBitBtn
      Left = 32
      Top = 24
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY K'#214'RLEV'#201'L T'#214'RL'#201'SE'
      TabOrder = 0
      OnClick = KLDELETEClick
    end
    object KLINSERT: TBitBtn
      Left = 32
      Top = 56
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY K'#214'RLEV'#201'L BESZUR'#193'SA'
      TabOrder = 1
      OnClick = KLINSERTClick
    end
    object BANSIGN: TBitBtn
      Left = 32
      Top = 88
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY SZIGN'#211' LETILT'#193'SA'
      TabOrder = 2
      OnClick = BANSIGNClick
    end
    object KLREADLIST: TBitBtn
      Left = 32
      Top = 120
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'RLEV'#201'L OLVAS'#193'SOK ID'#336'PONTJAI'
      ModalResult = 1
      TabOrder = 3
      OnClick = KLREADLISTClick
    end
    object KILEPOGOMB: TBitBtn
      Left = 32
      Top = 184
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P'#201'S A SUPERVISORI MEN'#220'B'#336'L'
      TabOrder = 5
      OnClick = KILEPOGOMBClick
    end
    object emailTMKGOMB: TBitBtn
      Left = 32
      Top = 152
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'E-MAIL C'#205'MEK KARBANTART'#193'SA'
      TabOrder = 4
      OnClick = emailTMKGOMBClick
    end
  end
  object DELPANEL: TPanel
    Left = -1600
    Top = 4
    Width = 657
    Height = 350
    BevelOuter = bvNone
    Color = clSilver
    TabOrder = 1
    object Label2: TLabel
      Left = 128
      Top = 8
      Width = 389
      Height = 36
      Caption = 'EGY K'#214'RLEV'#201'L T'#214'RL'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object DELRACS: TDBGrid
      Left = 8
      Top = 56
      Width = 641
      Height = 249
      DataSource = DELSOURCE
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'DATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#193'TUM'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'IKTATOSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'IKTAT'#211'SZ'#193'M'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TARTALOM'
          Title.Alignment = taCenter
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end>
    end
    object REMOVEGOMB: TBitBtn
      Left = 96
      Top = 312
      Width = 225
      Height = 25
      Cursor = crHandPoint
      Caption = 'EZT A K'#214'RLEVELET T'#214'R'#214'LNI'
      TabOrder = 1
      OnClick = REMOVEGOMBClick
    end
    object DELRETURNGOMB: TBitBtn
      Left = 336
      Top = 312
      Width = 225
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A F'#336'MEN'#220'RE'
      TabOrder = 2
      OnClick = DELRETURNGOMBClick
    end
  end
  object INSPANEL: TPanel
    Left = -1600
    Top = 24
    Width = 657
    Height = 350
    BevelOuter = bvNone
    Color = clMedGray
    TabOrder = 2
    object Label3: TLabel
      Left = 120
      Top = 8
      Width = 429
      Height = 36
      Caption = 'EGY K'#214'RLEV'#201'L BESZ'#218'R'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object INSRACS: TDBGrid
      Left = 8
      Top = 56
      Width = 641
      Height = 193
      DataSource = INSSOURCE
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'DATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#193'TUM'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'IKTATOSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'IKTAT'#211
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TARTALOM'
          Title.Alignment = taCenter
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end>
    end
    object VALASZTOGOMB: TBitBtn
      Left = 8
      Top = 286
      Width = 313
      Height = 25
      Cursor = crHandPoint
      Caption = 'BESZ'#218'RAND'#211' K'#214'RLEV'#201'L KIV'#193'LASZT'#193'SA'
      TabOrder = 1
      OnClick = VALASZTOGOMBClick
    end
    object INSERTGOMB: TBitBtn
      Left = 328
      Top = 286
      Width = 313
      Height = 25
      Cursor = crHandPoint
      Caption = 'BESZ'#218'R'#193'S A V'#193'LASZTOTT K'#214'RLEV'#201'L UT'#193'N'
      TabOrder = 2
      OnClick = INSERTGOMBClick
    end
    object VISSZAGOMB: TBitBtn
      Left = 168
      Top = 315
      Width = 313
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A F'#336'MEN'#220'RE'
      TabOrder = 3
      OnClick = VISSZAGOMBClick
    end
    object VALASZTOTTPANEL: TPanel
      Left = 8
      Top = 256
      Width = 633
      Height = 25
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
  end
  object FOLYAMATPANEL: TPanel
    Left = -600
    Top = 328
    Width = 433
    Height = 57
    BevelOuter = bvNone
    Caption = 'V'#201'GREHAJT'#193'S FOLYAMATBAN ....'
    Color = clRed
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object BANPANEL: TPanel
    Left = 150
    Top = 400
    Width = 385
    Height = 153
    TabOrder = 4
    object Label4: TLabel
      Left = 72
      Top = 24
      Width = 243
      Height = 24
      Caption = 'EGY SZIGN'#211' LETILT'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 56
      Top = 72
      Width = 117
      Height = 21
      Caption = 'Letiltott szign'#243':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object szignoedit: TEdit
      Left = 184
      Top = 68
      Width = 121
      Height = 32
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 5
      ParentFont = False
      TabOrder = 0
      OnEnter = szignoeditEnter
      OnExit = szignoeditExit
      OnKeyDown = szignoeditKeyDown
    end
    object tiltogomb: TBitBtn
      Left = 48
      Top = 112
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'LETILTVA'
      TabOrder = 1
      OnClick = tiltogombClick
    end
    object MEGSEMTILTGOMB: TBitBtn
      Left = 200
      Top = 112
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 2
      OnClick = MEGSEMTILTGOMBClick
    end
  end
  object FOCIMPANEL: TPanel
    Left = -330
    Top = 200
    Width = 457
    Height = 41
    BevelOuter = bvNone
    Caption = 'Egy k'#246'rlev'#233'l t'#246'rl'#233'se'
    Color = 4539717
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object EMAILPANEL: TPanel
    Left = -1200
    Top = 96
    Width = 745
    Height = 497
    Color = 11599871
    TabOrder = 6
    object Label6: TLabel
      Left = 152
      Top = 16
      Width = 469
      Height = 31
      Caption = 'AZ E-MAIL C'#205'MEK KARBANTART'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object EMAILRACS: TDBGrid
      Left = 24
      Top = 56
      Width = 689
      Height = 377
      BorderStyle = bsNone
      Color = 11599871
      DataSource = EMAILSOURCE
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnKeyDown = EMAILRACSKeyDown
      Columns = <
        item
          Expanded = False
          FieldName = 'NEV'
          Title.Alignment = taCenter
          Title.Caption = 'VEZET'#336' NEVE'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 321
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'EMAIL'
          Title.Alignment = taCenter
          Title.Caption = 'E-MAIL C'#205'ME'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end>
    end
    object EMAILMODIGOMB: TBitBtn
      Left = 16
      Top = 448
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'E-MAIL M'#211'DOSIT'#193'S'
      TabOrder = 1
      OnClick = EMAILMODIGOMBClick
    end
    object UJVEZETOGOMB: TBitBtn
      Left = 192
      Top = 448
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = #218'J VEZET'#336
      TabOrder = 2
      OnClick = UJVEZETOGOMBClick
    end
    object TORLOGOMB: TBitBtn
      Left = 368
      Top = 448
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'T'#214'RL'#201'S'
      TabOrder = 3
      OnClick = TORLOGOMBClick
    end
    object MENUREGOMB: TBitBtn
      Left = 544
      Top = 448
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A MEN'#220'RE'
      TabOrder = 4
      OnClick = MENUREGOMBClick
    end
    object MODIPANEL: TPanel
      Left = -777
      Top = 136
      Width = 561
      Height = 201
      BevelOuter = bvNone
      TabOrder = 5
      object Shape2: TShape
        Left = 0
        Top = 0
        Width = 561
        Height = 201
        Align = alClient
        Brush.Color = 16756991
        Pen.Color = clPurple
        Pen.Width = 5
      end
      object Label7: TLabel
        Left = 72
        Top = 80
        Width = 45
        Height = 22
        Caption = 'N'#201'V:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clMaroon
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label8: TLabel
        Left = 48
        Top = 120
        Width = 73
        Height = 22
        Caption = 'E-MAIL:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clMaroon
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label9: TLabel
        Left = 72
        Top = 24
        Width = 440
        Height = 40
        Caption = 'E-MAIL C'#205'M M'#211'DOSIT'#193'SA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clPurple
        Font.Height = -35
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        Transparent = True
      end
      object EMAILEDIT: TEdit
        Left = 128
        Top = 120
        Width = 409
        Height = 29
        CharCase = ecLowerCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        MaxLength = 50
        ParentFont = False
        TabOrder = 0
        Text = 'emailedit'
      end
      object NEVEDIT: TEdit
        Left = 128
        Top = 80
        Width = 409
        Height = 27
        BevelInner = bvNone
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 16756991
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        MaxLength = 40
        ParentFont = False
        ReadOnly = True
        TabOrder = 1
        Text = 'ASDEFRGTH ASDEFRGTZ ASEDEDFRTG ASEDFRGTZ'
      end
      object EMAILOKEGOMB: TBitBtn
        Left = 104
        Top = 160
        Width = 193
        Height = 25
        Cursor = crHandPoint
        Caption = 'ADATOK RENDBEN'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = EMAILOKEGOMBClick
      end
      object MEGSEMGOMB: TBitBtn
        Left = 312
        Top = 160
        Width = 193
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        OnClick = MEGSEMGOMBClick
      end
    end
    object ujvezetopanel: TPanel
      Left = -888
      Top = 144
      Width = 561
      Height = 201
      TabOrder = 6
      object Shape3: TShape
        Left = 1
        Top = 1
        Width = 559
        Height = 199
        Align = alClient
        Brush.Color = clLime
        Pen.Color = clTeal
        Pen.Width = 5
      end
      object Label10: TLabel
        Left = 88
        Top = 24
        Width = 398
        Height = 40
        Caption = #218'J VEZET'#336' FELV'#201'TELE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clGreen
        Font.Height = -35
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        Transparent = True
      end
      object Label11: TLabel
        Left = 64
        Top = 80
        Width = 45
        Height = 22
        Caption = 'N'#201'V:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clGreen
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label12: TLabel
        Left = 40
        Top = 112
        Width = 73
        Height = 22
        Caption = 'E-MAIL:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clGreen
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object UJNEVEDIT: TEdit
        Left = 120
        Top = 80
        Width = 393
        Height = 27
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        Text = 'UJNEVEDIT'
        OnKeyDown = UJNEVEDITKeyDown
      end
      object UJEMAILEDIT: TEdit
        Left = 120
        Top = 112
        Width = 393
        Height = 29
        CharCase = ecLowerCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 1
        Text = 'ujemailedit'
        OnKeyDown = UJEMAILEDITKeyDown
      end
      object UJNEVOKEGOMB: TBitBtn
        Left = 88
        Top = 152
        Width = 193
        Height = 25
        Cursor = crHandPoint
        Caption = 'ADATOK RENDBEN'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = UJNEVOKEGOMBClick
      end
      object UJNEVMEGSEMGOMB: TBitBtn
        Left = 296
        Top = 152
        Width = 193
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
      end
    end
    object TORLOPANEL: TPanel
      Left = -787
      Top = 168
      Width = 561
      Height = 201
      TabOrder = 7
      object Shape4: TShape
        Left = 1
        Top = 1
        Width = 559
        Height = 199
        Align = alClient
        Brush.Color = clRed
        Pen.Color = clWhite
        Pen.Width = 5
      end
      object Label13: TLabel
        Left = 136
        Top = 24
        Width = 326
        Height = 40
        Caption = 'EGY N'#201'V T'#214'RL'#201'SE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -35
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        Transparent = True
      end
      object Label14: TLabel
        Left = 64
        Top = 72
        Width = 45
        Height = 22
        Caption = 'N'#201'V:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label15: TLabel
        Left = 64
        Top = 104
        Width = 336
        Height = 31
        Caption = 'Biztosan t'#246'r'#246'ljem a list'#225'b'#243'l ?'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clYellow
        Font.Height = -27
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        Transparent = True
      end
      object TORLONEVEDIT: TEdit
        Left = 120
        Top = 72
        Width = 401
        Height = 27
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = clRed
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        ReadOnly = True
        TabOrder = 0
      end
      object TORLOOKEGOMB: TBitBtn
        Left = 88
        Top = 152
        Width = 193
        Height = 25
        Cursor = crHandPoint
        Caption = 'T'#214'R'#214'LNI'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = TORLOOKEGOMBClick
      end
      object TORLOMEGSEMGOMB: TBitBtn
        Left = 296
        Top = 152
        Width = 193
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = TORLOMEGSEMGOMBClick
      end
    end
  end
  object KORLQUERY: TIBQuery
    Database = KORLDBASE
    Transaction = KORLTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 24
    Top = 16
  end
  object KORLDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = KORLTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 16
  end
  object KORLTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KORLDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 16
  end
  object DELSOURCE: TDataSource
    DataSet = KORLQUERY
    Left = 128
    Top = 16
  end
  object KORLTABLA: TIBTable
    Database = KORLDBASE
    Transaction = KORLTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'DATUM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'IKTATOSZAM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'SORREND'
        DataType = ftSmallint
      end
      item
        Name = 'SORSZAM'
        DataType = ftSmallint
      end
      item
        Name = 'FILENEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 15
      end
      item
        Name = 'TARTALOM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 80
      end
      item
        Name = 'STORNO'
        DataType = ftSmallint
      end
      item
        Name = 'SORTEMP'
        DataType = ftSmallint
      end>
    IndexDefs = <
      item
        Name = 'ALTXKORL2015'
        Fields = 'SORREND'
      end>
    StoreDefs = True
    TableName = 'KORL2015'
    Left = 24
    Top = 48
  end
  object INSSOURCE: TDataSource
    DataSet = KORLQUERY
    Left = 128
    Top = 48
  end
  object OpenDialog1: TOpenDialog
    Left = 64
    Top = 48
  end
  object emailquery: TIBQuery
    Database = EMAILDBASE
    Transaction = EMAILTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 744
    Top = 16
  end
  object EMAILDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\MIDCHIEF.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = EMAILTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 776
    Top = 16
  end
  object EMAILTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = EMAILDBASE
    AutoStopAction = saNone
    Left = 776
    Top = 48
  end
  object EMAILSOURCE: TDataSource
    DataSet = emailquery
    Left = 744
    Top = 48
  end
  object PROSQUERY: TIBQuery
    Database = PROSDBASE
    Transaction = PROSTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 536
    Top = 464
  end
  object PROSDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PROSTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 568
    Top = 464
  end
  object PROSTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PROSDBASE
    AutoStopAction = saNone
    Left = 600
    Top = 464
  end
end
