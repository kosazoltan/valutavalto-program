object Form2: TForm2
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 277
  ClientWidth = 445
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
  object Label6: TLabel
    Left = 72
    Top = 40
    Width = 3
    Height = 13
  end
  object ALAPLAP: TPanel
    Left = 0
    Top = 0
    Width = 441
    Height = 273
    TabOrder = 0
    object Shape2: TShape
      Left = 1
      Top = 1
      Width = 439
      Height = 271
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label3: TLabel
      Left = 24
      Top = 32
      Width = 389
      Height = 25
      Caption = 'TRANZAKCI'#211' ENGED'#201'LYEZ'#201'SE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 64
      Top = 120
      Width = 99
      Height = 19
      Caption = 'A p'#233'nz forr'#225'sa:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 72
      Top = 152
      Width = 88
      Height = 19
      Caption = 'Egy'#233'b forr'#225's:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label10: TLabel
      Left = 72
      Top = 184
      Width = 85
      Height = 19
      Caption = 'Enged'#233'lyez'#337':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object UZENOPANEL: TPanel
      Left = 16
      Top = 64
      Width = 401
      Height = 41
      BevelOuter = bvNone
      Caption = 'Az '#252'gyf'#233'l strat'#233'giai hi'#225'nyoss'#225'gu orsz'#225'gb'#243'l j'#246'tt'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object FORRASCOMBO: TComboBox
      Left = 168
      Top = 120
      Width = 193
      Height = 24
      Cursor = crDrag
      DropDownCount = 9
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ItemHeight = 16
      ParentFont = False
      TabOrder = 1
      OnChange = FORRASCOMBOChange
      Items.Strings = (
        'J'#214'VEDELEM'
        'MEGTAKAR'#205'T'#193'S'
        'AJ'#193'ND'#201'K'
        #214'R'#214'KS'#201'G'
        'NYEREM'#201'NY'
        'K'#214'LCS'#214'N HITEL'
        'INGATLAN '#201'RT'#201'KES'#205'T'#201'S'
        'SAJ'#193'T TRANSZFER'
        'EGY'#201'B FORR'#193'S')
    end
    object EGYEBEDIT: TEdit
      Left = 168
      Top = 152
      Width = 193
      Height = 24
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnEnter = ENGEDELYEZOEDITEnter
      OnExit = ENGEDELYEZOEDITExit
      OnKeyDown = EGYEBEDITKeyDown
    end
    object ENGEDELYEZOEDIT: TEdit
      Left = 168
      Top = 184
      Width = 193
      Height = 24
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnEnter = ENGEDELYEZOEDITEnter
      OnExit = ENGEDELYEZOEDITExit
      OnKeyDown = ENGEDELYEZOEDITKeyDown
    end
    object RENDBENGOMB: TBitBtn
      Left = 32
      Top = 224
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'Enged'#233'ly megad'#225'sa'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = RENDBENGOMBClick
    end
    object MEGSEMGOMB: TBitBtn
      Left = 224
      Top = 224
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'Nem enged'#233'lyezett'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = MEGSEMGOMBClick
    end
    object EGYEBTAKARO: TPanel
      Left = -368
      Top = 168
      Width = 409
      Height = 25
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 6
    end
    object STRATEGIAPANEL: TPanel
      Left = -1890
      Top = 64
      Width = 409
      Height = 193
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 7
      Visible = False
      object Label1: TLabel
        Left = 16
        Top = 40
        Width = 384
        Height = 22
        Caption = 'AZ '#220'GYF'#201'L STRAT'#201'GIAI HI'#193'NYOS'#193'GGAL'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label2: TLabel
        Left = 56
        Top = 72
        Width = 317
        Height = 22
        Caption = 'RENDELKEZ'#336' ORSZ'#193'GB'#211'L J'#214'TT ?'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object YESGOMB: TBitBtn
        Left = 72
        Top = 128
        Width = 129
        Height = 25
        Cursor = crHandPoint
        Caption = 'IGEN'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = YESGOMBClick
      end
      object NOGOMB: TBitBtn
        Left = 208
        Top = 128
        Width = 129
        Height = 25
        Cursor = crHandPoint
        Caption = 'NEM'
        TabOrder = 1
        OnClick = NOGOMBClick
      end
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 16
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 8
    Top = 48
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 8
    Top = 88
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTimer
    Left = 8
    Top = 128
  end
end
