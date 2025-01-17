part of logger_flutter;

int _bufferSize = 250;

class LogConsole extends StatefulWidget {
  final bool dark;
  final bool showCloseButton;
  final bool borderEnable;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool isRoot;
  LogConsole({
    this.dark = false,
    this.showCloseButton = false,
    this.borderEnable = true,
    this.padding,
    this.backgroundColor,
    this.isRoot = false,
  }) : super(key: isRoot ? rootKey : null);

  @override
  LogConsoleState createState() => LogConsoleState();
}

class LogConsoleState extends State<LogConsole> {
  List<TextSpan> filteredBuffer = [];
  var _scrollController = ScrollController();
  double _logFontSize = 16;
  bool _scrollListenerEnabled = true;
  bool _followBottom = true;

  @override
  void initState() {
    super.initState();
    if (rootKey.currentState != null && !widget.isRoot) {
      filteredBuffer =
          List<TextSpan>.from(rootKey.currentState!.filteredBuffer);
    }
    eventBus.on<LogMessage>().listen((event) {
      if (filteredBuffer.length == _bufferSize) {
        filteredBuffer.removeAt(0);
      }
      filteredBuffer.add(_renderMessage(event.message));
      setState(() {});
    });
    _scrollController.addListener(() {
      if (!_scrollListenerEnabled) return;
      var scrolledToBottom = _scrollController.offset >=
          _scrollController.position.maxScrollExtent;
      setState(() {
        _followBottom = scrolledToBottom;
      });
    });
  }

  TextSpan _renderMessage(String message) {
    var parser = AnsiParser(dark: widget.dark);
    parser.parse(message);
    return TextSpan(children: parser.spans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.0),
      body: Container(
        padding: widget.borderEnable ? EdgeInsets.all(10) : null,
        decoration: widget.borderEnable
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: widget.backgroundColor,
                border: Border.all(
                  color: Colors.grey,
                  width: 5.0,
                ),
              )
            : BoxDecoration(color: widget.backgroundColor),
        child: _buildLogContent(),
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _followBottom ? 0 : 1,
        duration: Duration(milliseconds: 150),
        child: Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: FloatingActionButton(
            mini: true,
            clipBehavior: Clip.antiAlias,
            child: Icon(
              Icons.arrow_downward,
              color: widget.dark ? Colors.white : Colors.lightBlue[900],
            ),
            onPressed: _scrollToBottom,
          ),
        ),
      ),
    );
  }

  Widget _buildLogContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: widget.borderEnable ? EdgeInsets.all(10) : widget.padding,
          height: constraints.maxHeight,
          decoration: widget.borderEnable
              ? BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(10))
              : null,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1600,
              child: ListView.builder(
                shrinkWrap: true,
                controller: _scrollController,
                itemBuilder: (context, index) {
                  var logEntry = filteredBuffer[index];
                  return Text.rich(
                    logEntry,
                    style: GoogleFonts.lato(fontSize: _logFontSize),
                  );
                },
                itemCount: filteredBuffer.length,
              ),
            ),
          ),
        );
      },
    );
  }

  void _scrollToBottom() async {
    _scrollListenerEnabled = false;

    setState(() {
      _followBottom = true;
    });

    var scrollPosition = _scrollController.position;
    await _scrollController.animateTo(
      scrollPosition.maxScrollExtent,
      duration: new Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );

    _scrollListenerEnabled = true;
  }

  @override
  void dispose() {
    //Logger.removeOutputListener(_callback);
    super.dispose();
  }
}
