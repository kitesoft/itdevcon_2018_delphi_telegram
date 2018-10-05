program ConsoleBot;

{$APPTYPE CONSOLE}
{$R *.res}

{ /$DEFINE  USE_INDY_CORE }
uses
{$IFDEF  USE_INDY_CORE} // Indy Http Core
  CrossUrl.Indy.HttpClient,
{$ELSE}                 // System.Net HTTP Core
  CrossUrl.SystemNet.HttpClient,
{$ENDIF}
  Rest.Json,
  System.SysUtils,
  TelegAPI.Receiver.Console,
  TelegAPI.Bot,
  TelegAPI.Types,
  TelegAPI.Bot.Impl,
  TelegAPI.Logger,
  TelegAPI.Logger.Old,
  TelegAPI.Types.ReplyMarkups, TelegAPI.Types.Enums, System.Json,
  System.Generics.Collections, TelegAPI.Types.InlineQueryResults,
  TelegAPI.Types.InputMessageContents, TelegAPI.Types.Impl;

const
  TOKEN = '632038595:AAHeF3VVS9zsDblXAcLP2398caAP7dOAWqs';

procedure Main;
var
  LBot: ITelegramBot;
  LReceiver: TtgReceiverConsole;
  LExcp: TtgExceptionManagerConsole;
  LStop: string;
  LMarkup: IReplyMarkup;
  LParseMode: TtgParseMode;
  LChatID: Int64;
begin
{$IFDEF  USE_INDY_CORE}
  LBot := TTelegramBot.Create(TOKEN, TcuHttpClientIndy.Create(nil));
{$ELSE}
  LBot := TTelegramBot.Create(TOKEN, TcuHttpClientSysNet.Create(nil));
{$ENDIF}
  LReceiver := TtgReceiverConsole.Create(LBot);
  LBot.Logger := TtgExceptionManagerConsole.Create(nil);
  try
    LExcp := LBot.Logger as TtgExceptionManagerConsole;
    LExcp.OnLog := procedure(level: TLogLevel; msg: string; e: Exception)
      begin
        if level >= TLogLevel.Error then
        begin
          if Assigned(e) then
            Writeln('[' + e.ToString + '] ' + msg)
          else
            Writeln(msg);
        end;
      end;
    LReceiver.OnStart := procedure
      begin
        Writeln('started');
      end;
    LReceiver.OnStop := procedure
      begin
        Writeln('stopped');
      end;
    // ON INLINE INPUT CALLBACK
    LReceiver.OnCallbackQuery := procedure(ACallback: ItgCallbackQuery)
      var
        I: Int64;
      begin
        Writeln('RECEIVED callback: ', ACallback.data, ' From ',
          ACallback.From.Id);
        // ACCEPT OR REFUSE ORDER
        if ACallback.data.ToLower.Equals('accept') or
          ACallback.data.ToLower.Equals('refuse') then
        begin
          if ACallback.data.ToLower.Equals('accept') then
          begin
            LBot.AnswerCallbackQuery(ACallback.Id, 'Order accepted!');
          end
          else if ACallback.data.ToLower.Equals('refuse') then
          begin
            LBot.AnswerCallbackQuery(ACallback.Id, 'Order refused!');
          end;

          LBot.SendMessage(ACallback.From.Id, 'Lista generica degli ordini:',
            LParseMode, FALSE, FALSE, 0);

          // CICLO LA LISTA E STAMPO GLI ORDINI
          for I := 1 to 3 do
          begin
            LMarkup := TtgInlineKeyboardMarkup.Create([
              { first row }
              [TtgInlineKeyboardButton.Create('Open order', 'singleorder')]]);
            LBot.SendMessage(ACallback.From.Id, 'Piccolo tab dell''ordine con: '
              + sLineBreak + 'Nome: ----' + sLineBreak + 'Data ordine: ----' +
              sLineBreak + 'Prezzo: ----' + sLineBreak + 'Cliente: ----' +
              sLineBreak + 'Descrizione: ---+-+-+-+-+-+' + sLineBreak,
              LParseMode, FALSE, FALSE, 0, LMarkup)
          end
        end

        // PAYMENT
        else if ACallback.data.ToLower.Equals('pagamento') then
        begin
          Writeln('RECEIVED payment : From ', ACallback.From.Id);
          // LBot.SendInvoice(ACallback.From.Id, 'Titolo', 'Descrizione',
          // 'Payload', '284685063:TEST:MzQ1ODhhODM4Yzk0', 'start_parameter',
          // 'EUR', [TtgLabeledPrice.Create('label', 6000)]);
        end

        // SINGLE ORDER
        else if ACallback.data.ToLower.Equals('singleorder') then
        begin
          LMarkup := TtgInlineKeyboardMarkup.Create([
            { first row }
            [TtgInlineKeyboardButton.Create('Accetta', 'accept'),
            TtgInlineKeyboardButton.Create('Rifiuta', 'refuse')]]);
          LBot.SendMessage(ACallback.From.Id, 'Ordine selezionato:' + sLineBreak
            + 'Nome: ----' + sLineBreak + 'Data ordine: ----' + sLineBreak +
            'Prezzo: ----' + sLineBreak + 'Cliente: ----' + sLineBreak +
            'Descrizione: ---+-+-+-+-+-+' + sLineBreak, LParseMode, FALSE,
            FALSE, 0, LMarkup)
        end;

      end;

    LReceiver.OnChosenInlineResult :=
        procedure(AChosenInlineResult: ItgChosenInlineResult)
      begin
        Writeln('RECEIVED chosen query: ', AChosenInlineResult.Query, ' From ',
          AChosenInlineResult.From.Id);
        LBot.SendMessage(AChosenInlineResult.From.Id,
          'Stampa dell''ordine da pagare' + sLineBreak + 'Nome: ----' +
          sLineBreak + 'Data ordine: ----' + sLineBreak + 'Prezzo: ----' +
          sLineBreak + 'Cliente: ----' + sLineBreak +
          'Descrizione: ---+-+-+-+-+-+' + sLineBreak, LParseMode, FALSE,
          FALSE, 0);
      end;

    // ON INLINE REQUEST
    LReceiver.OnInlineQuery := procedure(AInlineQuery: ItgInlineQuery)
      var
        results: TArray<TtgInlineQueryResult>;
      begin
        Writeln('RECEIVED query: ', AInlineQuery.Query, ' From ',
          AInlineQuery.From.Id);
        results := [TtgInlineQueryResultLocation.Create,
          TtgInlineQueryResultLocation.Create];
        with TtgInlineQueryResultLocation(results[0]) do
        begin
          Id := '1';
          Latitude := 40.7058316;
          Longitude := -74.2581888;
          Title := 'New York';
          InputMessageContent := TtgInputLocationMessageContent.Create(Latitude,
            Longitude);
        end;
        with TtgInlineQueryResultLocation(results[1]) do
        begin
          Id := '2';
          Latitude := 50.4021367;
          Longitude := -30.2525032;
          Title := 'New York';
          InputMessageContent := TtgInputLocationMessageContent.Create(Latitude,
            Longitude);
        end;
        LBot.AnswerInlineQuery(AInlineQuery.Id, results, 0, FALSE);
      end;

    // ON MESSAGE RECEIVED
    LReceiver.OnMessage := procedure(AMessage: ItgMessage)
      var
        I: Int64;
      begin
        LChatID := AMessage.From.Id;
        Writeln(AMessage.From.Id, ': ', AMessage.Text);

        if AMessage.Text.ToLower.Contains('start') or
          AMessage.Text.ToLower.Contains('home') then
        begin
          // START OR HOME
          LMarkup := TtgReplyKeyboardMarkup.Create([
            { first row }
            [TtgKeyboardButton.Create('Orders', FALSE, FALSE),
            TtgKeyboardButton.Create('Invoices', FALSE, FALSE)],
            { second row }
            [TtgKeyboardButton.Create('Home', FALSE, FALSE)]], TRUE);

          LBot.SendMessage(AMessage.From.Id, 'Benvenuto nel bot order! ' +
            AMessage.From.Username + sLineBreak + 'Ci sono 20 ordini: ' +
            sLineBreak + '- 5 sono completati ' + sLineBreak +
            '- 11 sono pending ' + sLineBreak + '- 4 sono rifiutati',
            LParseMode, FALSE, FALSE, 0, LMarkup)
        end
        // ORDERS
        else if AMessage.Text.ToLower.Equals('orders') or
          AMessage.Text.ToLower.Equals('/orders') then
        begin;
          LMarkup := TtgReplyKeyboardMarkup.Create([
            { first row }
            [TtgKeyboardButton.Create('Completed Orders', FALSE, FALSE),
            TtgKeyboardButton.Create('Refused Orders', FALSE, FALSE),
            TtgKeyboardButton.Create('Pending Orders', FALSE, FALSE)],
            { second row }
            [TtgKeyboardButton.Create('Home', FALSE, FALSE)]], TRUE);

          LBot.SendMessage(AMessage.From.Id, 'Lista generica degli ordini:',
            LParseMode, FALSE, FALSE, 0, LMarkup);

          // CICLO LA LISTA E STAMPO GLI ORDINI
          for I := 1 to 3 do
          begin
            LMarkup := TtgInlineKeyboardMarkup.Create([
              { first row }
              [TtgInlineKeyboardButton.Create('Open order', 'singleorder')]]);
            LBot.SendMessage(AMessage.From.Id, 'Piccolo tab dell''ordine con ' +
              sLineBreak + 'Nome: ----' + sLineBreak + 'Data ordine: ----' +
              sLineBreak + 'Prezzo: ----' + sLineBreak + 'Cliente: ----' +
              sLineBreak + 'Descrizione: ---+-+-+-+-+-+' + sLineBreak,
              LParseMode, FALSE, FALSE, 0, LMarkup)
          end
        end
        // COMPLETED ORDERS
        else if AMessage.Text.ToLower.Equals('completed orders') then
        begin
          LBot.SendMessage(AMessage.From.Id, 'Lista degli ordini completati: ',
            LParseMode, FALSE, FALSE, 0);

          for I := 1 to 5 do
          begin
            LMarkup := TtgInlineKeyboardMarkup.Create([
              { first row }
              [TtgInlineKeyboardButton.Create('Open order', 'singleorder')]]);
            LBot.SendMessage(AMessage.From.Id, 'Piccolo tab dell''ordine con ' +
              sLineBreak + 'Nome: ----' + sLineBreak + 'Data ordine: ----' +
              sLineBreak + 'Prezzo: ----' + sLineBreak + 'Cliente: ----' +
              sLineBreak + 'Descrizione: ---+-+-+-+-+-+' + sLineBreak,
              LParseMode, FALSE, FALSE, 0, LMarkup)
          end
        end
        // PENDING ORDERS
        else if AMessage.Text.ToLower.Equals('pending orders') then
        begin
          LBot.SendMessage(AMessage.From.Id, 'Lista degli ordini in attesa: ',
            LParseMode, FALSE, FALSE, 0);

          for I := 1 to 7 do
          begin
            LMarkup := TtgInlineKeyboardMarkup.Create([
              { first row }
              [TtgInlineKeyboardButton.Create('Open order', 'singleorder')]]);
            LBot.SendMessage(AMessage.From.Id, 'Piccolo tab dell''ordine con ' +
              sLineBreak + 'Nome: ----' + sLineBreak + 'Data ordine: ----' +
              sLineBreak + 'Prezzo: ----' + sLineBreak + 'Cliente: ----' +
              sLineBreak + 'Descrizione: ---+-+-+-+-+-+' + sLineBreak,
              LParseMode, FALSE, FALSE, 0, LMarkup)
          end
        end
        // REFUSED ORDERS
        else if AMessage.Text.ToLower.Equals('refused orders') then
        begin
          LBot.SendMessage(AMessage.From.Id, 'Lista degli ordini rifiutati: ',
            LParseMode, FALSE, FALSE, 0);

          for I := 1 to 2 do
          begin
            LMarkup := TtgInlineKeyboardMarkup.Create([
              { first row }
              [TtgInlineKeyboardButton.Create('Open order', 'singleorder')]]);
            LBot.SendMessage(AMessage.From.Id, 'Piccolo tab dell''ordine con ' +
              sLineBreak + 'Nome: ----' + sLineBreak + 'Data ordine: ----' +
              sLineBreak + 'Prezzo: ----' + sLineBreak + 'Cliente: ----' +
              sLineBreak + 'Descrizione: ---+-+-+-+-+-+' + sLineBreak,
              LParseMode, FALSE, FALSE, 0, LMarkup)
          end
        end
        // INVOICES
        else if AMessage.Text.ToLower.Equals('invoices') or
          AMessage.Text.ToLower.Equals('/invoices') then
        begin
          LMarkup := TtgReplyKeyboardMarkup.Create([
            { first row }
            [TtgKeyboardButton.Create('Orders', FALSE, FALSE)],
            { second row } [TtgKeyboardButton.Create('Home', FALSE,
            FALSE)]], TRUE);
          LBot.SendMessage(AMessage.From.Id, 'Lista completa delle fatture: ',
            LParseMode, FALSE, FALSE, 0, LMarkup);

          // CICLO LA LISTA E STAMPO GLI ORDINI
          for I := 1 to 3 do
          begin
            LMarkup := TtgInlineKeyboardMarkup.Create([
              { first row }
              [TtgInlineKeyboardButton.Create('Pay', 'pagamento')]]);
            LBot.SendMessage(AMessage.From.Id, 'Fattura No ' + inttostr(I) +
              sLineBreak + 'Nome: ----' + sLineBreak + 'Data ordine: ----' +
              sLineBreak + 'Prezzo: ----' + sLineBreak + 'Cliente: ----' +
              sLineBreak + 'Descrizione: ---+-+-+-+-+-+' + sLineBreak,
              LParseMode, FALSE, FALSE, 0, LMarkup)
          end
        end
        else
          LBot.SendMessage(AMessage.From.Id,
            'Nnnnnnnon ho capito! Spiegati meglio...');
      end;

    Writeln('Bot nick: ', LBot.GetMe.Username);
    LReceiver.IsActive := TRUE;

    while LStop.ToLower.Trim <> 'exit' do
    begin
      Readln(LStop);
      if LStop.ToLower.Trim = 'stop' then
        LReceiver.IsActive := FALSE
      else if LStop.ToLower.Trim = 'start' then
        LReceiver.IsActive := TRUE;
    end;
  finally
    LReceiver.Free;
  end;
end;

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
    Main;
  except
    on e: Exception do
      Writeln(e.ClassName, ': ', e.message);
  end;

end.
