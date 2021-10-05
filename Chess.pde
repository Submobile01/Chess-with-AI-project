final int boardSize = 800;
final int squareSize = boardSize/8;
final int WHITE = 1;
final int BLACK = -1;
final int ROOK = 20;
final int KNIGHT = 21;
final int BISHOP = 22;
final int QUEEN = 23;
final int KING = 24;
final int PAWN = 25;
Board board;
Piece selectedPiece = new Piece(0,0);
AI ai;
AI ai2;
double evalBar;
boolean start;
void setup(){
  size(800,800);
  board = new Board();
  ai = new AI(2,-1);
  //ai2 = new AI(3,1);
  //background(128,233,83);
}

void draw(){
  board.drawBoard();
  if(start){
    ai.move(board);
    //ai2.move(board);
  }
  //println("turn is " + board.turn);
}

void mousePressed(){
  if(mouseButton == LEFT){
    start = true;
    board.select();
    /*for(int i=0; i<board.pieces.size(); i++){
      Piece piece = board.pieces.get(i);
      piece.setSquaresVision(board);//dont forget there's no clear for square vision
      //piece.setValue();
    }*/
    Square square = board.getSquare();
    println("move squares: " + square.piece.detectMoves(board));
    println("vision squares: " + square.piece.detectVision(board));
    println("piece value: " + square.piece.value);
    println("square controlled: " + square.visioned[0] + " and " + square.visioned[1]);
    //println(board.getSquare());
  }
  else{//remove piece for test
    board.pieces.remove(board.getSquare().piece);
    board.getSquare().piece = new Piece(0,0);
    board.getSquare().occupied = false;
  }
}

void mouseReleased(){
  if(mouseButton == LEFT){
    board.deselect();
    
    //print(board.turn);
  }
}

void keyPressed(){
  if(key == 'r'){
    board.flip();
  }
  if(key == 'e'){
    board.evaluate();
    println(-1 + " material count: " + board.materialCount(-1));
    println("eval: " + board.eval);
  }
}

class AI{
  int depth;
  int side;
  
  AI(int depth, int side){
    this.depth = depth; 
    this.side = side;
  }
  double[] minimax(Board theBoard, int depth, double alpha, double beta, int pieceInd, int squareInd){
    int turn = theBoard.turn;
    //int mated = theBoard.mated();
    //if(mated == 2) return new double[]{0,pieceInd,squareInd};
    //else if(mated == 1) return new double[]{-turn*100000,pieceInd,squareInd};
    if(depth == 0) return new double[]{theBoard.evaluate(),pieceInd,squareInd};
    if(turn == 1){
      double maxEval = -100000;
      outer:
      for(int i=0; i<theBoard.pieces.size(); i++){
        Piece piece = theBoard.pieces.get(i);
        if(piece.sideId == turn){
          piece.detectMoves(theBoard);
          for(int j=0; j<piece.moveSquares.size(); j++){
            Square square = piece.moveSquares.get(j);
            double eval = minimax(theBoard.getMoved(piece,square),depth-1, alpha, beta, pieceInd, squareInd)[0];
            if(maxEval < eval){
              maxEval = eval;
              pieceInd = i;
              squareInd = j;
            }
            if(alpha < eval) alpha = eval;
            if(alpha > beta) break outer;
          }
        }
      }
      return new double[]{maxEval,pieceInd,squareInd};
    }
    else if(turn == -1){
      double minEval = 100000;
      outer:
      for(int i=0; i<theBoard.pieces.size(); i++){
        Piece piece = theBoard.pieces.get(i);
        if(piece.sideId == turn){
          piece.detectMoves(theBoard);
          for(int j=0; j<piece.moveSquares.size(); j++){
            Square square = piece.moveSquares.get(j);
            double eval = minimax(theBoard.getMoved(piece,square),depth-1, alpha, beta, pieceInd, squareInd)[0];
            if(minEval > eval){
              minEval = eval;
              pieceInd = i;
              squareInd = j;
            }
            if(beta > eval) beta = eval;
            if(alpha > beta) break outer;
          }
        }
      }
      return new double[]{minEval,pieceInd,squareInd};
    }
    return new double[]{1.111,pieceInd,squareInd};
    
  }
  
  void move(Board theBoard){
    if(theBoard.turn == side){
      double[] array = minimax(theBoard,depth,-100000,100000,-1,-1);
      Piece piece = theBoard.pieces.get((int)array[1]);
      theBoard.deselect(piece,piece.moveSquares.get((int)array[2]));
    }
  }
}

class Board{
  color[] colorset;//0 light, 1 dark 
  int size = boardSize;
  Square[][] squares;
  ArrayList<Piece> pieces = new ArrayList<Piece>();
  int turn = 1;
  double eval;
  boolean flipped;
  Board(){
    colorset = new color[2];
    colorset[0] = color(88,170,88);
    colorset[1] = color(240,255,240);
    squares = new Square[10][10];
    setupSquares();
    setStandardPositions();
  }
  
  Board(ArrayList<Piece> newPieces){
    colorset = new color[2];
    colorset[0] = color(88,170,88);
    colorset[1] = color(240,255,240);
    squares = new Square[10][10];
    setupSquares();
    pieces = newPieces;
    fillSquares();
  }
  void drawBoard(){
    for(int i=0; i<10; i++){
      for(int j=0; j<10; j++){
        if(i==0 || i==10 || j==0 || j==10) continue;
        squares[i][j].drawIt();
      }
    }
    for(int i=0; i<pieces.size(); i++) pieces.get(i).drawIt();
  }
  
  void flip(){
    for(int i=1; i<9; i++){
      for(int j=1; j<9; j++){
        squares[i][j].flipped = !squares[i][j].flipped;
      }
    }
    for(int i=0; i<pieces.size(); i++) pieces.get(i).flipped = !pieces.get(i).flipped;
    flipped = !flipped;
  }
  
  void setupSquares(){
    for(int i=0; i<10; i++){
      for(int j=0; j<10; j++){
        squares[i][j] = new Square(i,j,size/8,colorset);
      }
    }
  }
  
  int[] getCoordinate(){
    int x = 1 + mouseX/(size/8);
    int y = 8 - mouseY/(size/8);
    //print( squares[y][x].toString() );
    if(!flipped)return new int[]{x,y};
    else return new int[]{(9-x),(9-y)};
  }
  
  Square getSquare(){
    int x = 1 + mouseX/(size/8);
    int y = 8 - mouseY/(size/8);
    //print( squares[y][x].toString() );
    if(!flipped) return squares[y][x];
    else return squares[9-y][9-x];
  }
  
  void setStandardPositions(){
    for(int i=20; i<23; i++){//normal pieces
      //white 
      pieces.add(new Piece(1, i-19, 1, i));
      pieces.add(new Piece(1, 9-(i-19), 1, i));
      //black
      pieces.add(new Piece(-1, i-19, 8, i));
      pieces.add(new Piece(-1, 9-(i-19), 8, i));
    }
    //queen and king
      //white
      pieces.add(new Piece(1, 23-19, 1, QUEEN));
      pieces.add(new Piece(1, 24-19, 1, KING));
      //black
      pieces.add(new Piece(-1, 23-19, 8, QUEEN));
      pieces.add(new Piece(-1, 24-19, 8, KING));
    //pawns
      //white
      for(int i=1; i<9; i++) pieces.add(new Piece(1, i, 2, PAWN));
      //black
      for(int i=1; i<9; i++) pieces.add(new Piece(-1, i, 7, PAWN));
    //fill the squares
    
    
    //pieces.add(new Piece(-1,6,3,QUEEN));
    
    fillSquares();
    //set turn to white
    turn = 1;
  }
  
  ArrayList<Piece> clonePieces() {
    ArrayList<Piece> newPieces = new ArrayList<Piece>();
    for(int i=0; i<pieces.size(); i++) newPieces.add(pieces.get(i).cloneSelf());
    return newPieces;
  }
  
  
  
  boolean checked(){// checking
    for(int i=0; i<pieces.size(); i++){
      Piece piece = pieces.get(i);
      if(piece.id == KING && piece.sideId != turn){
        //println(turn + " checked: " + piece.threatened(this));
        return piece.threatened(this);
      }
    }
    //print(turn + " checked: " + false);
    return false;
  }
  
  
  
  boolean checked(int side){//checked
    for(int i=0; i<pieces.size(); i++){
      Piece piece = pieces.get(i);
      if(piece.id == KING && piece.sideId == turn){
        //println(turn + " checked: " + piece.threatened(this));
        return piece.threatened(this);
      }
    }
    //print(turn + " checked: " + false);
    return false;
  }
  
  int mated(){
    for(int i=0; i<pieces.size(); i++){
      Piece piece = pieces.get(i);
      if(piece.sideId == turn){
        piece.detectMoves(this);
        for(int j=0; j<piece.moveSquares.size(); j++){
          Square square = piece.moveSquares.get(j);
          if(!getMoved(piece,square).checked()) return 0;
        }
      }
    }
    if(checked(1)) return 1;
    else return 2;
  }
  
  void select(){
    Square square = getSquare();
    if(square.occupied){
      square.piece.selected = true;
      selectedPiece = square.piece;
    }
  }
  
  void deselect(){
    Square square = getSquare();
    if(selectedPiece.real){
      if(selectedPiece.checkLegal(board, square) && !getMoved(selectedPiece,square).checked()){
        if(selectedPiece.promoting(square)){
          pieces.remove(selectedPiece);
          selectedPiece = new Piece(selectedPiece.sideId, selectedPiece.posX, selectedPiece.posY, QUEEN);
          pieces.add(selectedPiece);
        }
        selectedPiece.moveToSquare(this, square);
        if(selectedPiece.castling == 2 || selectedPiece.castling == -2){
          Piece rook = selectedPiece.getCastleRook(this);
          //println(rook);
          rook.moveToSquare(this, squares[selectedPiece.posY][selectedPiece.posX-selectedPiece.castling/2]);
          turn*=-1;
          selectedPiece.castling = 0;
        }
        selectedPiece = new Piece(0,0);
      }
      else{
        selectedPiece.selected = false;
        selectedPiece = new Piece(0,0);
      }
      int mated = mated();
      println("checkmate: " + (mated == 1) );
      println("stalemate: " + (mated == 2) );
    }
  }
  
  void deselect(Piece selectedPiece, Square square){
    if(selectedPiece.real){
      if(selectedPiece.id == KING) if(selectedPiece.castle(this).contains(square)){
        selectedPiece.castling = square.x-selectedPiece.posX;
      }
      if(selectedPiece.promoting(square)){
        pieces.remove(selectedPiece);
        selectedPiece = new Piece(selectedPiece.sideId, selectedPiece.posX, selectedPiece.posY, QUEEN);
        pieces.add(selectedPiece);
      }
      selectedPiece.moveToSquare(this, square);
      if(selectedPiece.castling == 2 || selectedPiece.castling == -2){
        Piece rook = selectedPiece.getCastleRook(this);
        rook.moveToSquare(this, squares[selectedPiece.posY][selectedPiece.posX-selectedPiece.castling/2]);
        turn*=-1;
        selectedPiece.castling = 0;
      }
      //selectedPiece = new Piece(0,0);
      else{
        //selectedPiece.selected = false;
        //selectedPiece = new Piece(0,0);
      }
      //int mated = mated();
      //println("checkmate: " + (mated == 1) );
      //println("stalemate: " + (mated == 2) );
    }
  }
  
  void fillSquares(){
    for(int i=0; i<pieces.size(); i++){
      Piece piece = pieces.get(i);
      int posX = piece.posX; 
      int posY = piece.posY;
      squares[posY][posX].piece = piece;
      squares[posY][posX].occupied = true;
    }
  }
  
  Board getMoved(Piece piece, Square toSquare){
    Board newBoard = new Board(this.clonePieces());
    newBoard.turn = this.turn;
    int ind = pieces.indexOf(piece);
    newBoard.deselect(newBoard.pieces.get(ind), toSquare);
    return newBoard;
  }
  
  double evaluate(){
    eval = 0;
    /*
    for(int i=1; i<9; i++){
      for(int j=1; j<9; j++){
        Square square = squares[i][j];
        square.visioned[0] = 0;
        square.visioned[1] = 0;
      }
    }
    for(int i=0; i<pieces.size(); i++){
      Piece piece = pieces.get(i);
      piece.setSquaresVision(this);//dont forget there's no clear for square vision
      piece.setValue();
    }
    for(int i=0; i<pieces.size(); i++){
      pieces.get(i).diminishValue(this);
      eval += pieces.get(i).value;
    }
    for(int i=1; i<9; i++){
      for(int j=1; j<9; j++){
        Square square = squares[i][j];
        eval+=square.getValue()*(square.visioned[0]-square.visioned[1]);
      }
    }*/
    
    // simple stuff
    for(int i=0; i<pieces.size(); i++){
      Piece piece = pieces.get(i);
      piece.setValue(this);
      eval += piece.value;
    }
    
    return eval;
  }
  
  int materialCount(int side){
    int count = 0;
    for(int i=0; i<pieces.size(); i++){
      Piece piece = pieces.get(i);
      if(piece.sideId == side) count+=piece.material;
    }
    return count;
  }
}

class Piece{
  PImage image;
  String side;
  int sideId;
  String name;
  int posX, posY; 
  int id;
  double material;//material value
  double value;
  boolean selected;
  boolean real;
  boolean moved;
  boolean justMoved;
  boolean flipped;
  int castling;
  boolean enpassant;
  int promoY;
  ArrayList<Square> squares = new ArrayList<Square>();//placeholder
  ArrayList<Square> moveSquares = new ArrayList<Square>();//moves
  ArrayList<Square> visionSquares = new ArrayList<Square>();//visions
  Piece(int side, int x, int y, int pieceID){
    posX = x;
    posY = y;
    id = pieceID;
    sideId = side;
    if(side == 1) this.side = "white";
    else if(side == -1) this.side = "black";
    setPieceName(id);
    image = loadImage(this.side + name + ".png");
    selected = false;
    real = true;
    setMaterial();
  }
  
  Piece(int x, int y){
    posX = x;
    posY = y;
    id = 0;
    setPieceName(id);
    selected = false;
    real = false;
  }
  
  Piece cloneSelf(){
    return new Piece(sideId, posX, posY, id);
  }
  
  void drawIt(){
    if(!selected){
      if(!flipped) image(image, (posX-1)*squareSize, boardSize-posY*squareSize, squareSize, squareSize);
      else  image(image, (8-posX)*squareSize, boardSize-(9-posY)*squareSize, squareSize, squareSize);
    }
    else{
      image(image, mouseX-squareSize/2, mouseY-squareSize/2, squareSize, squareSize);
    }
  }
  void setPos(int x, int y){
    posX = x;
    posY = y;
  }
  
  void setPos(Square square){
    posX = square.x;
    posY = square.y;
  }
  void setPieceName(int id){
    switch(id){
      case ROOK:
        name = "Rook";
        break;
      case KNIGHT:
        name = "Knight";
        break;
      case BISHOP:
        name = "Bishop";
        break;
      case QUEEN:
        name = "Queen";
        break;
      case KING:
        name = "King";
        break;
      case PAWN:
        name = "Pawn";
        break;
      default:
        name = "None";
        break;
    }
  }
  
  boolean checkLegal(Board theBoard, Square square){
    if(sideId == theBoard.turn){
      if(id == KING) if(castle(theBoard).contains(square)){
        castling = square.x-posX;
        return true;
      }
      detectMoves(theBoard);
      if(moveSquares.contains(square))return true;
      /*if(id == PAWN){
        if(pawnPush(theBoard).contains(square)) return true;
        //if(
      }*/
    }
    return false;
  }
  
  boolean threatened(Board theBoard){
    for(int i=0; i<theBoard.pieces.size(); i++){
      Piece piece = theBoard.pieces.get(i);
      if(piece.sideId != this.sideId){
        if(piece.detectVision(theBoard).contains(theBoard.squares[posY][posX])) return true;
      }
    }
    return false;
  }
  
  void setSquaresVision(Board theBoard){
    detectVision(theBoard);
    int ind = -1;
    if(sideId == 1) ind = 0;
    else if(sideId == -1) ind = 1;
    for(int i=0; i<visionSquares.size(); i++){
      Square square = visionSquares.get(i);
      square.visioned[ind]+=1;
    }
  }
  ArrayList<Square> detectMoves(Board board){
    //ArrayList<Square> squares = new ArrayList<Square>();
    squares.clear();
    moveSquares.clear();
    switch(id){
        case ROOK:
        moveSquares = rookMoves(board, 1, 1);
        break;
      case KNIGHT:
        moveSquares = knightMoves(board);
        break;
      case BISHOP:
        moveSquares = bishopMoves(board,1,1);
        break;
      case QUEEN:
        moveSquares = queenMoves(board);
        break;
      case KING:
        moveSquares = kingMoves(board);
        moveSquares.addAll(castle(board));
        break;
      case PAWN:
        moveSquares = pawnMoves(board);
        moveSquares.addAll(pawnPush(board));
        break;
      default:
        //return false;
    }
    return moveSquares;
  }
  
  /*ArrayList<Square> detectVision(Board board){
    visionSquares.clear();
    detectMoves(board);//might not be neccesssary
    ArrayList<Square> squares = detectProtect(board);
    squares.addAll(detectMoves(board));
    visionSquares = squares;
    return squares;
  }*/
  
  ArrayList<Square> detectVision(Board board){
    visionSquares.clear();
    switch(id){
        case ROOK:
        visionSquares = rookVision(board, 1, 1);
        break;
      case KNIGHT:
        visionSquares = knightVision(board);
        break;
      case BISHOP:
        visionSquares = bishopVision(board,1,1);
        break;
      case QUEEN:
        visionSquares = queenVision(board);
        break;
      case KING:
        visionSquares = kingVision(board);
        break;
      case PAWN:
        visionSquares = pawnVision(board);
        break;
      default:
        //return false;
    }
    return visionSquares;
  }
  
  ArrayList<Square> rookMoves(Board theBoard, int counter, int direction){//counter, direction should start at 1
    //ArrayList<Square> squares = new ArrayList<Square>();
    //left
    if(direction == 1){
      Square square = theBoard.squares[posY][posX-counter];
      if(posX-counter < 1 || posX-counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
        counter = 1;
        direction++;
      }
      else{
        squares.add(square);
        rookMoves(theBoard, counter+1, direction);
      }
    }
    //right
    if(direction == 2){
      Square square = theBoard.squares[posY][posX+counter];
      if(posX+counter < 1 || posX+counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
        counter = 1;
        direction++;
      }
     else{
       squares.add(square);
       rookMoves(theBoard, counter+1, direction);
     }
    }
    //up
    if(direction == 3){
      Square square = theBoard.squares[posY+counter][posX];
      if(posY+counter < 1 || posY+counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
        counter = 1;
        direction++;
      }
      else{
        squares.add(square);
        rookMoves(theBoard, counter+1, direction);
      }
    }
    //down
    if(direction == 4){
      Square square = theBoard.squares[posY-counter][posX];
      if(posY-counter < 1 || posY-counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
        counter = 1;
        direction++;
      }
      else{
        squares.add(square);
        rookMoves(theBoard, counter+1, direction);
      }
    }

    return squares;
  }
  
  ArrayList<Square> bishopMoves(Board theBoard, int counter, int direction){//counter, direction should start at 1
    //ArrayList<Square> squares = new ArrayList<Square>();
    //left up
    //print(posX+" " + posY);
    if(direction == 1){
      Square square = theBoard.squares[posY+counter][posX-counter];
      if(posX-counter < 1 || posX-counter > 8 || posY+counter < 1 || posY+counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
        counter = 1;
        direction++;
      }
      else{
        squares.add(square);
        bishopMoves(theBoard, counter+1, direction);
      }
    }
    //right up
    if(direction == 2){
      Square square = theBoard.squares[posY+counter][posX+counter];
      if(posX+counter < 1 || posX+counter > 8 || posY+counter < 1 || posY+counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
        counter = 1;
        direction++;
      }
     else{
       squares.add(square);
       bishopMoves(theBoard, counter+1, direction);
     }
    }
    //left down
    if(direction == 3){
      Square square = theBoard.squares[posY-counter][posX-counter];
      if(posX-counter < 1 || posX-counter > 8 || posY-counter < 1 || posY-counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
        counter = 1;
        direction++;
      }
      else{
        squares.add(square);
        bishopMoves(theBoard, counter+1, direction);
      }
    }
    //right down
    if(direction == 4){
      Square square = theBoard.squares[posY-counter][posX+counter];
      if(posX+counter < 1 || posX+counter > 8 || posY-counter < 1 || posY-counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
        counter = 1;
        direction++;
      }
      else{
        squares.add(square);
        bishopMoves(theBoard, counter+1, direction);
      }
    }

    return squares;
  }
  
  ArrayList<Square> queenMoves(Board theBoard){
    //ArrayList<Square> squares = new ArrayList<Square>();
    rookMoves(theBoard,1,1);
    bishopMoves(theBoard,1,1);
    return squares;
  }
  
  ArrayList<Square> knightMoves(Board theBoard){
    //ArrayList<Square> squares = new ArrayList<Square>();
    Square square;
    //from left slightly up clockwise
    if(onBoard(posY+1,posX-2)){
      square = theBoard.squares[posY+1][posX-2];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY+2,posX-1)){
      square = theBoard.squares[posY+2][posX-1];
      //print(square.occupied);
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY+2,posX+1)){
      square = theBoard.squares[posY+2][posX+1];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY+1,posX+2)){
      square = theBoard.squares[posY+1][posX+2];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY-1,posX+2)){
      square = theBoard.squares[posY-1][posX+2];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY-2,posX+1)){
      square = theBoard.squares[posY-2][posX+1];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY-2,posX-1)){
      square = theBoard.squares[posY-2][posX-1];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY-1,posX-2)){
      square = theBoard.squares[posY-1][posX-2];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    return squares;
  }
  
  ArrayList<Square> kingMoves(Board theBoard){
    //ArrayList<Square> squares = new ArrayList<Square>();
    Square square;
    //from left up clockwise
    if(onBoard(posY+1,posX-1)){
      square = theBoard.squares[posY+1][posX-1];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY+1,posX)){
      square = theBoard.squares[posY+1][posX];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY+1,posX+1)){
      square = theBoard.squares[posY+1][posX+1];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY,posX+1)){
      square = theBoard.squares[posY][posX+1];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY-1,posX+1)){
      square = theBoard.squares[posY-1][posX+1];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY-1,posX)){
      square = theBoard.squares[posY-1][posX];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY-1,posX-1)){
      square = theBoard.squares[posY-1][posX-1];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    if(onBoard(posY,posX-1)){
      square = theBoard.squares[posY][posX-1];
      if(square.occupied){
        if(square.piece.side == this.side);
        else squares.add(square);
      }else squares.add(square);
    }
    return squares;
  }
  
  ArrayList<Square> pawnMoves(Board theBoard){
    //ArrayList<Square> squares = new ArrayList<Square>();
    //squares.clear();
    Square square;
    if(onBoard(posY+sideId,posX+1)){
      square = theBoard.squares[posY+sideId][posX+1];
      if(square.occupied && square.piece.sideId != this.sideId) squares.add(square);//need to add en passant
    }
    if(onBoard(posY+sideId,posX-1)){
      square = theBoard.squares[posY+sideId][posX-1];
      if(square.occupied && square.piece.sideId != this.sideId) squares.add(square);//need to add en passant
    }
    squares.addAll(pawnEnPassant(theBoard));
    return squares;
  }
  
  ArrayList<Square> pawnPush(Board theBoard){
    ArrayList<Square> squares = new ArrayList<Square>();
    Square square;
    if(onBoard(posY+sideId,posX)){//push once
      square = theBoard.squares[posY+sideId][posX];
      if(!square.occupied){
        squares.add(square);
      }
    }
    if(onBoard(posY+sideId*2,posX)){//push twice
      square = theBoard.squares[posY+sideId*2][posX];
      if((sideId == 1 && posY == 2) || sideId == -1 && posY == 7){
        if(!moved && !square.occupied && !theBoard.squares[posY+sideId][posX].occupied) squares.add(square);
      }
    }
    return squares;
  }
  
  ArrayList<Square> pawnEnPassant(Board theBoard){
    ArrayList<Square> squares = new ArrayList<Square>();
    Square square;
    if(onBoard(posY+sideId,posX+1)){
      square = theBoard.squares[posY][posX+1];
      if(square.occupied && square.piece.justMoved && square.piece.sideId != this.sideId){
        if(posY == 4 || posY == 5){
          squares.add(theBoard.squares[posY+sideId][posX+1]);
          enpassant = true;
        }
      }
    }
    if(onBoard(posY+sideId,posX-1)){
      square = theBoard.squares[posY][posX-1];
      if(square.occupied && square.piece.justMoved && square.piece.sideId != this.sideId){
        if(posY == 4 || posY == 5){
          squares.add(theBoard.squares[posY+sideId][posX-1]);
          enpassant = true;
        }
      }
    }
    return squares;
  }
  
  ArrayList<Square> castle(Board theBoard){
    ArrayList<Square> squares = new ArrayList<Square>();
    Square square1,square2;
    //short castle
    if(onBoard(posY,posX+2)){
      square2 = theBoard.squares[posY][posX+2];
      square1 = theBoard.squares[posY][posX+1];
      if(!this.moved && !theBoard.squares[posY][8].piece.moved)
      if(!square1.occupied && !square2.occupied){
        if(square1.getVisioned(theBoard, sideId*-1) == 0 && square2.getVisioned(theBoard, sideId*-1) == 0)
          squares.add(square2);
      }
    }
    //long castle
    if(onBoard(posY,posX-2)){
      square2 = theBoard.squares[posY][posX-2];
      square1 = theBoard.squares[posY][posX-1];
      if(!this.moved && !theBoard.squares[posY][1].piece.moved)
      if(!square1.occupied && !square2.occupied){
        if(square1.getVisioned(theBoard, sideId*-1) == 0 && square2.getVisioned(theBoard, sideId*-1) == 0)
          squares.add(square2);
      } 
    }
    return squares;
  }
  
  Piece getCastleRook(Board theBoard){
    int y = posY;
    int x = 0;
    if(castling == 2) x = 8;
    else if(castling == -2) x = 1;
    for(int i=0; i<theBoard.pieces.size(); i++){
      Piece piece = theBoard.pieces.get(i);
      if(piece.posX == x && piece.posY == y) return piece;
    }
    return null;
  }
  
  ArrayList<Square> rookVision(Board theBoard, int counter, int direction){//counter, direction should start at 1
    //ArrayList<Square> squares = new ArrayList<Square>();
    //left
    if(direction == 1){
      Square square = theBoard.squares[posY][posX-counter];
      if(posX-counter < 1 || posX-counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
        counter = 1;
        direction++;
      }
      else{
        visionSquares.add(square);
        rookVision(theBoard, counter+1, direction);
      }
    }
    //right
    if(direction == 2){
      Square square = theBoard.squares[posY][posX+counter];
      if(posX+counter < 1 || posX+counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
        counter = 1;
        direction++;
      }
     else{
       visionSquares.add(square);
       rookVision(theBoard, counter+1, direction);
     }
    }
    //up
    if(direction == 3){
      Square square = theBoard.squares[posY+counter][posX];
      if(posY+counter < 1 || posY+counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
        counter = 1;
        direction++;
      }
      else{
        visionSquares.add(square);
        rookVision(theBoard, counter+1, direction);
      }
    }
    //down
    if(direction == 4){
      Square square = theBoard.squares[posY-counter][posX];
      if(posY-counter < 1 || posY-counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
        counter = 1;
        direction++;
      }
      else{
        visionSquares.add(square);
        rookVision(theBoard, counter+1, direction);
      }
    }

    return visionSquares;
  }
  
  ArrayList<Square> bishopVision(Board theBoard, int counter, int direction){//counter, direction should start at 1
    //ArrayList<Square> squares = new ArrayList<Square>();
    //left up
    //print(posX+" " + posY);
    if(direction == 1){
      Square square = theBoard.squares[posY+counter][posX-counter];
      if(posX-counter < 1 || posX-counter > 8 || posY+counter < 1 || posY+counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
        counter = 1;
        direction++;
      }
      else{
        visionSquares.add(square);
        bishopVision(theBoard, counter+1, direction);
      }
    }
    //right up
    if(direction == 2){
      Square square = theBoard.squares[posY+counter][posX+counter];
      if(posX+counter < 1 || posX+counter > 8 || posY+counter < 1 || posY+counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
        counter = 1;
        direction++;
      }
     else{
       visionSquares.add(square);
       bishopVision(theBoard, counter+1, direction);
     }
    }
    //left down
    if(direction == 3){
      Square square = theBoard.squares[posY-counter][posX-counter];
      if(posX-counter < 1 || posX-counter > 8 || posY-counter < 1 || posY-counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
        counter = 1;
        direction++;
      }
      else{
        visionSquares.add(square);
        bishopVision(theBoard, counter+1, direction);
      }
    }
    //right down
    if(direction == 4){
      Square square = theBoard.squares[posY-counter][posX+counter];
      if(posX+counter < 1 || posX+counter > 8 || posY-counter < 1 || posY-counter > 8){//when out of border
         counter = 1;
         direction++;
      }
      else if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
        counter = 1;
        direction++;
      }
      else{
        visionSquares.add(square);
        bishopVision(theBoard, counter+1, direction);
      }
    }

    return visionSquares;
  }
  
  ArrayList<Square> queenVision(Board theBoard){
    //ArrayList<Square> squares = new ArrayList<Square>();
    rookVision(theBoard,1,1);
    bishopVision(theBoard,1,1);
    return visionSquares;
  }
  
  ArrayList<Square> knightVision(Board theBoard){
    //ArrayList<Square> squares = new ArrayList<Square>();
    Square square;
    //from left slightly up clockwise
    if(onBoard(posY+1,posX-2)){
      square = theBoard.squares[posY+1][posX-2];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY+2,posX-1)){
      square = theBoard.squares[posY+2][posX-1];
      //print(square.occupied);
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY+2,posX+1)){
      square = theBoard.squares[posY+2][posX+1];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY+1,posX+2)){
      square = theBoard.squares[posY+1][posX+2];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY-1,posX+2)){
      square = theBoard.squares[posY-1][posX+2];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY-2,posX+1)){
      square = theBoard.squares[posY-2][posX+1];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY-2,posX-1)){
      square = theBoard.squares[posY-2][posX-1];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY-1,posX-2)){
      square = theBoard.squares[posY-1][posX-2];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    return visionSquares;
  }
  
  ArrayList<Square> kingVision(Board theBoard){
    //ArrayList<Square> squares = new ArrayList<Square>();
    Square square;
    //from left up clockwise
    if(onBoard(posY+1,posX-1)){
      square = theBoard.squares[posY+1][posX-1];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY+1,posX)){
      square = theBoard.squares[posY+1][posX];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY+1,posX+1)){
      square = theBoard.squares[posY+1][posX+1];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY,posX+1)){
      square = theBoard.squares[posY][posX+1];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY-1,posX+1)){
      square = theBoard.squares[posY-1][posX+1];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY-1,posX)){
      square = theBoard.squares[posY-1][posX];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY-1,posX-1)){
      square = theBoard.squares[posY-1][posX-1];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    if(onBoard(posY,posX-1)){
      square = theBoard.squares[posY][posX-1];
      if(square.occupied){
        //if(square.piece.side != this.side);
        //else 
        visionSquares.add(square);
      }else visionSquares.add(square);
    }
    return visionSquares;
  }
  
  ArrayList<Square> pawnVision(Board theBoard){
    //ArrayList<Square> squares = new ArrayList<Square>();
    //squares.clear();
    Square square;
    if(onBoard(posY+sideId,posX+1)){
      square = theBoard.squares[posY+sideId][posX+1];
      //if(square.occupied && square.piece.sideId == this.sideId) squares.add(square);
      //else if(!square.occupied) 
      visionSquares.add(square);
    }
    if(onBoard(posY+sideId,posX-1)){
      square = theBoard.squares[posY+sideId][posX-1];
      //if(square.occupied && square.piece.sideId == this.sideId) squares.add(square);
      //else if(!square.occupied) 
      visionSquares.add(square);
    }
    return visionSquares;
  }
  
  boolean promoting(Square square){
    if(id == PAWN){
      if((sideId == -1 && square.y == 1) || (sideId == 1 && square.y == 8)) return true;
    }
    return false;
  }
  
  void moveToSquare(Board theBoard, Square square){
    //remove piece in original square
    square = theBoard.squares[square.y][square.x]; 
    theBoard.squares[posY][posX].piece = new Piece(posX,posY);
    theBoard.squares[posY][posX].occupied = false;
    selected = false;
    //set internal pos
    setPos(square);
    //take pieces
    if(square.occupied) theBoard.pieces.remove(square.piece);
    square.occupied = true;
    if(enpassant){
      theBoard.pieces.remove(theBoard.squares[square.y-sideId][square.x].piece);
      theBoard.squares[square.y-sideId][square.x].piece = new Piece(square.y-sideId,square.x);
    }
    for(int i=0; i<theBoard.pieces.size(); i++){
      theBoard.pieces.get(i).justMoved = false;
      theBoard.pieces.get(i).enpassant = false;
    }
    //if(theBoard.mated()!=0) start = false;
    square.piece = this;//add piece in to square
    moved = true;
    justMoved = true;
    //alternate turn
    theBoard.turn*=-1;
  }
  
  void setMaterial(){
    switch(id){
      case ROOK:
        material = 500;
        break;
      case KNIGHT:
        material = 320;
        break;
      case BISHOP:
        material = 330;
        break;
      case QUEEN:
        material = 900;
        break;
      case KING:
        material = 20000;
        break;
      case PAWN:
        material = 100;
        break;
      default:
        material = 0;
        break;
    }
  }
  
  void setValue(Board theBoard){//positional and squares controlled
    double[][] posMat;
    value = sideId * material;
    switch(id){
      case ROOK:
        posMat = new double[][]{{0,  0,  0,  0,  0,  0,  0,  0},
                                {5, 10, 10, 10, 10, 10, 10,  5},
                               {-5,  0,  0,  0,  0,  0,  0, -5},
                               {-5,  0,  0,  0,  0,  0,  0, -5},
                               {-5,  0,  0,  0,  0,  0,  0, -5},
                               {-5,  0,  0,  0,  0,  0,  0, -5},
                               {-5,  0,  0,  0,  0,  0,  0, -5},
                                {0,  0,  0,  5,  0,  5,  0,  0}};
        if(sideId == 1) value += sideId*posMat[8-posY][8-posX];
        else value += sideId*posMat[posY-1][posX-1];
        break;
      case KNIGHT:
        posMat = new double[][]{{-50,-40,-30,-30,-30,-30,-40,-50},
                                {-40,-20,  0,  0,  0,  0,-20,-40},
                                {-30,  0, 10, 15, 15, 10,  0,-30},
                                {-30,  5, 15, 20, 20, 15,  5,-30},
                                {-30,  0, 15, 20, 20, 15,  0,-30},
                                {-30,  5, 10, 15, 15, 10,  5,-30},
                                {-40,-20,  0,  5,  5,  0,-20,-40},
                                {-50,-40,-30,-30,-30,-30,-40,-50}};
        value+=sideId*posMat[posY-1][posX-1];
        break;
      case BISHOP:
        posMat = new double[][]{{-20,-10,-10,-10,-10,-10,-10,-20},
                                {-10,  0,  0,  0,  0,  0,  0,-10},
                                {-10,  0,  5, 10, 10,  5,  0,-10},
                                {-10,  5,  5, 10, 10,  5,  5,-10},
                                {-10,  0, 10, 10, 10, 10,  0,-10},
                                {-10, 10, 10, 10, 10, 10, 10,-10},
                                {-10,  5,  0,  0,  0,  0,  5,-10},
                                {-20,-10,-10,-10,-10,-10,-10,-20}};
        value+=sideId*posMat[posY-1][posX-1];
        break;
      case QUEEN:
        posMat = new double[][]{{-20,-10,-10, -5, -5,-10,-10,-20},
                                {-10,  0,  0,  0,  0,  0,  0,-10},
                                {-10,  0,  5,  5,  5,  5,  0,-10},
                                 {-5,  0,  5,  5,  5,  5,  0, -5},
                                  {0,  0,  5,  5,  5,  5,  0, -5},
                                {-10,  5,  5,  5,  5,  5,  0,-10},
                                {-10,  0,  5,  0,  0,  0,  0,-10},
                                {-20,-10,-10, -5, -5,-10,-10,-20}};
        value+=sideId*posMat[posY-1][posX-1];
        break;
      case KING:
        if(theBoard.materialCount(sideId*-1) > 21500)posMat = new double[][]{{-30,-40,-40,-50,-50,-40,-40,-30},
                                {-30,-40,-40,-50,-50,-40,-40,-30},
                                {-30,-40,-40,-50,-50,-40,-40,-30},
                                {-30,-40,-40,-50,-50,-40,-40,-30},
                                {-20,-30,-30,-40,-40,-30,-30,-20},
                                {-10,-20,-20,-20,-20,-20,-20,-10},
                                 {20, 20,  0,  0,  0,  0, 20, 20},
                                 {20, 30, 20,  0,  0, 10, 40, 20}};
        else posMat = new double[][]{{-50,-40,-30,-20,-20,-30,-40,-50},
                                    {-30,-20,-10,  0,  0,-10,-20,-30},
                                    {-30,-10, 20, 30, 30, 20,-10,-30},
                                    {-30,-10, 30, 40, 40, 30,-10,-30},
                                    {-30,-10, 30, 40, 40, 30,-10,-30},
                                    {-30,-10, 20, 30, 30, 20,-10,-30},
                                    {-30,-30,  0,  0,  0,  0,-30,-30},
                                    {-50,-30,-30,-30,-30,-30,-30,-50}};
        if(sideId == 1) value += sideId*posMat[8-posY]
        [8-posX];
        else value += sideId*posMat[posY-1][posX-1];
        break;
      case PAWN:
        posMat =  new double[][]{{0,  0,  0,  0,  0,  0,  0,  0},
                                {50, 50, 50, 50, 50, 50, 50, 50},
                                {10, 10, 20, 30, 30, 20, 10, 10},
                                 {5,  5, 10, 25, 25, 10,  5,  5},
                                 {0,  0,  0, 20, 20,  0,  0,  0},
                                 {5, -5,-10,  0,  0,-10, -5,  5},
                                 {5, 10, 10,-20,-20, 10, 10,  5},
                                 {0,  0,  0,  0,  0,  0,  0,  0}};
        if(sideId == 1) value += sideId*posMat[8-posY][8-posY];
        else value += sideId*posMat[posY-1][posX-1];
        break;
        default:
        break;
    }
  }
  
  void diminishValue(Board theBoard){
    int v[] = theBoard.squares[posY][posX].visioned;
    int visioned = v[0]-v[1];
    if(visioned == 0);
    else if(visioned == -1){
      if(sideId == 1) value/=2;
      else value*=1.2;
    }
    else if(visioned == 1){
      if(sideId == -1) value/=2;
      else value*=1.2;
    }
    else if(visioned <= -2){
      if(sideId == 1) value/=4;
      else value*=1.34;
    }
    else if(visioned >= 2){
      if(sideId == -1) value/=4;
      else value*=1.34;
    }
  }
  
  boolean onBoard(int y, int x){//beware
    //print(!(x < 1 || x > 8 || y < 1 || y > 8));
    return !(x < 1 || x > 8 || y < 1 || y > 8);
  }
  
  String toString(){
    return side + " " + name + " at " + board.squares[posY][posX];
  }
}

class Square{
  color col;
  int x,y;//1 - 8
  String coordinateName;
  int size;
  boolean occupied;
  Piece piece;
  int[] visioned = new int[2];
  boolean flipped;
  Square(int y, int x, int size, color[] colorset){
    col = colorset[(x+y) % 2];
    this.x = x;
    this.y = y;
    this.size = size;
    coordinateName = "" + (char)(96+x) + "" + y;
    piece = new Piece(x,y);
  }
  void drawIt(){
    stroke(200);
    fill(col);
    if(!flipped) rect(boardSize-y*size, (x-1)*size, size, size);
    else rect(boardSize-(9-y)*size, (8-x)*size, size, size);
  }
  
  int getVisioned(Board theBoard, int side){
    int count = 0;
    ArrayList<Piece> pieces = theBoard.pieces;
    for(int i=0; i<pieces.size(); i++){
      Piece piece = pieces.get(i);
      if(piece.sideId == side){
        if(piece.detectVision(theBoard).contains(this)){
          count++;
        }
      }
    }
    if(side == 1) visioned[0] = count;
    else visioned[1] = count;
    return count;
  }
  
  double getValue(){
    double value = ((4.5-Math.abs(4.5-x))+(4.5-Math.abs(4.5-y)))*3;
    return value;
  }
  String toString(){
    return coordinateName;
  }
}