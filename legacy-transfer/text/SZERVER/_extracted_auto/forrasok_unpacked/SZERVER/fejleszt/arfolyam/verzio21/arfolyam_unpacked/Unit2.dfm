object INTERNETTMKFORM: TINTERNETTMKFORM
  Left = 192
  Top = 114
  AlphaBlend = True
  AlphaBlendValue = 230
  BorderStyle = bsNone
  Caption = 'INTERNETTMKFORM'
  ClientHeight = 449
  ClientWidth = 696
  Color = clRed
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 681
    Height = 433
    TabOrder = 0
    object Shape1: TShape
      Left = 152
      Top = 88
      Width = 369
      Height = 145
      Shape = stRoundRect
    end
    object Label1: TLabel
      Left = 288
      Top = 96
      Width = 87
      Height = 33
      Caption = 'MEN'#220
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 32
      Top = 32
      Width = 591
      Height = 36
      Caption = 'AZ INTERNETC'#205'MEK KARBANTART'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object UJINTERNETGOMB: TBitBtn
      Left = 160
      Top = 136
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY '#218'J INTERNET C'#205'M BE'#193'LLIT'#193'SA'
      TabOrder = 0
      OnClick = UJINTERNETGOMBClick
      OnEnter = UJINTERNETGOMBEnter
      OnExit = UJINTERNETGOMBExit
    end
    object INTERNETDELETEGOMB: TBitBtn
      Left = 160
      Top = 168
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY INTERNET C'#205'M T'#214'RL'#201'SE'
      TabOrder = 1
      OnClick = INTERNETDELETEGOMBClick
      OnEnter = UJINTERNETGOMBEnter
      OnExit = UJINTERNETGOMBExit
    end
    object VISSZAGOMB: TBitBtn
      Left = 160
      Top = 200
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA AZ ALAPLAP SZERKESZT'#201'SHEZ'
      TabOrder = 2
      OnClick = VISSZAGOMBClick
      OnEnter = UJINTERNETGOMBEnter
      OnExit = UJINTERNETGOMBExit
    end
    object UJINTERNETPANEL: TPanel
      Left = 24
      Top = 256
      Width = 641
      Height = 161
      BevelOuter = bvNone
      TabOrder = 3
      object Label3: TLabel
        Left = 144
        Top = 16
        Width = 340
        Height = 21
        Caption = 'EGY '#218'J INTERNETC'#205'M REGISZTR'#193'L'#193'SA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label4: TLabel
        Left = 16
        Top = 48
        Width = 148
        Height = 15
        Caption = 'A R'#214'GZITEND'#336' URL CIM:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label5: TLabel
        Left = 16
        Top = 80
        Width = 174
        Height = 15
        Caption = 'A MEGH'#205'V'#211' GOMB FEL'#205'RATA:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label6: TLabel
        Left = 368
        Top = 80
        Width = 155
        Height = 13
        Caption = 'H'#193'NYADIK GOMB: (0-20 k'#246'z'#246'tt)'
      end
      object INTERNETCIMEDIT: TEdit
        Left = 168
        Top = 44
        Width = 465
        Height = 21
        TabOrder = 0
        OnEnter = INTERNETCIMEDITEnter
        OnExit = INTERNETCIMEDITExit
        OnKeyDown = INTERNETCIMEDITKeyDown
      end
      object GOMBFELIRATEDIT: TEdit
        Left = 200
        Top = 76
        Width = 145
        Height = 21
        MaxLength = 18
        TabOrder = 1
        OnEnter = INTERNETCIMEDITEnter
        OnExit = INTERNETCIMEDITExit
        OnKeyDown = GOMBFELIRATEDITKeyDown
      end
      object GOMBSZAMEDIT: TEdit
        Left = 532
        Top = 77
        Width = 80
        Height = 21
        TabOrder = 2
        OnEnter = INTERNETCIMEDITEnter
        OnExit = INTERNETCIMEDITExit
        OnKeyDown = GOMBSZAMEDITKeyDown
      end
      object UJURLOKEGOMB: TBitBtn
        Left = 120
        Top = 112
        Width = 193
        Height = 25
        Cursor = crHandPoint
        Caption = #218'J INTERNETC'#205'M RENDBEN'
        TabOrder = 3
        OnClick = UJURLOKEGOMBClick
        OnEnter = UJINTERNETGOMBEnter
        OnExit = UJINTERNETGOMBExit
        OnMouseMove = UJINTERNETGOMBMouseMove
      end
      object UJURLMEGSEMGOMB: TBitBtn
        Left = 328
        Top = 112
        Width = 193
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        TabOrder = 4
        OnClick = UJURLMEGSEMGOMBClick
        OnEnter = UJINTERNETGOMBEnter
        OnExit = UJINTERNETGOMBExit
        OnMouseMove = UJINTERNETGOMBMouseMove
      end
    end
    object URLTORLOPANEL: TPanel
      Left = 8
      Top = 200
      Width = 665
      Height = 225
      BevelOuter = bvNone
      TabOrder = 4
      object Label7: TLabel
        Left = 24
        Top = 16
        Width = 354
        Height = 19
        Caption = 'V'#193'LASSZA KI  A T'#214'RLEND'#336' INTERNETC'#205'MET'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label8: TLabel
        Left = 416
        Top = 112
        Width = 206
        Height = 21
        Caption = 'BIZTOSAN T'#214'R'#214'LJEM ?'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object INTERNETCIMLISTA: TListBox
        Left = 24
        Top = 48
        Width = 353
        Height = 161
        Color = 11599871
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ItemHeight = 17
        Items.Strings = (
          'OTP     fttp://www.otpbank.hu')
        ParentFont = False
        TabOrder = 0
        OnDblClick = INTERNETCIMLISTADblClick
      end
      object DELCIMPANEL: TPanel
        Left = 392
        Top = 64
        Width = 257
        Height = 33
        BevelOuter = bvNone
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 1
      end
      object TORLOGOMB: TBitBtn
        Left = 392
        Top = 160
        Width = 121
        Height = 25
        Cursor = crHandPoint
        Caption = 'T'#214'R'#214'LNI'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
        OnClick = TORLOGOMBClick
      end
      object MEGSEMGOMB: TBitBtn
        Left = 528
        Top = 160
        Width = 121
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
        OnClick = MEGSEMGOMBClick
      end
      object TAKAROPANEL: TPanel
        Left = 384
        Top = 104
        Width = 281
        Height = 97
        BevelOuter = bvNone
        TabOrder = 4
      end
    end
  end
end
