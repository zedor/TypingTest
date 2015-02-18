package  {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	//import for valve assets
	import flash.utils.getDefinitionByName;

	// mask rectangle
	import flash.display.Sprite;
	
	//text stuff
	import flash.text.TextField;
	import flash.text.Font;
	import flash.text.TextFormat;
	import flash.display.Shape;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	public class TypingTest extends Minigame{
		
		var winH:int = 175;
		var winW:int = 400;
		
		var leaderboard:String = "Words per minute";
		var holderGame:MovieClip = new MovieClip;
		var holderMain:MovieClip = new MovieClip;
		var maskTxt:Shape = new Shape;
		var holderText:MovieClip = new MovieClip;
		var holderScore:MovieClip = new MovieClip;
		var vText:Vector.<TextField> = new Vector.<TextField>;
		var vString:Vector.<String> = new Vector.<String>;
		var wordList:Vector.<String> = new Vector.<String>;
		var inputField:TextField = new TextField;
		var btnSubmit:MovieClip;
		var inFieldFormat:TextFormat;
		/*var countField:TextField = new TextField;
		var ctFieldFormat:TextFormat;*/
		var topScoreField:TextField = new TextField;
		var topScoreFieldFormat:TextFormat;
		var gtField:TextField = new TextField;
		var gtFieldFormat:TextFormat;
		var scoreField:TextField = new TextField;
		var scFieldFormat:TextFormat;
		var startRow:Number;
		var buffY:int;
		var gameData:Object;
		
		var selColor:uint = 0x303030; // no idea
		var failColor:uint = 0x990000; // red
		var goodColor:uint = 0x00cc00; // green
		var normColor:uint = 0xffffff; // white
		
		var currentWord:int;
		var buffWord:String;
		
		var gameTimer:Timer;
		//var ctTimer:Timer;
		var gameRunning:Boolean = false;
		var consumingInput:Boolean = false;
		var awaitKey:Boolean = false;
		var score:int;
		
		public function TypingTest() {
			this.title = "Typing Test";
			this.minigameID = "123";
		}
		
		private function startGame( e:MouseEvent ) {
			stage.focus = null;
			holderGame.visible = true;
			holderMain.visible = false;
			holderScore.visible = false;
			holderText.y = 75;
			//countField.visible = false;
			
			while( vText.length > 0 ) {
				holderText.removeChild(vText[vText.length-1]);
				vText.pop();
			}
			
			while( vString.length > 0 ) {
				vString.pop();
			}
			
			populateText();
			currentWord = 0;
			buffWord = "";
			for( var i:int = 0; i < vString.length; i++ ) {
				addWord(vString[i]);
			}
			
			if (!consumingInput){
				globals.GameInterface.AddKeyInputConsumer();
				consumingInput = true;
			}
			
			startRow = vText[currentWord].y;
			vText[currentWord].background = true;
			vText[currentWord].backgroundColor = selColor;
			
			inputField.text = buffWord;
			inputField.setTextFormat(inFieldFormat);
			
			score = 0;
			gameTimer.reset();
			gtField.text = "60.0";
			gtField.setTextFormat(gtFieldFormat);
			awaitKey = true;
			gameRunning = true;
		}
		
		private function changeGameCountdown( e:TimerEvent ) {
			gtField.text = int(59-int(gameTimer.currentCount / 10)).toString();
			gtField.appendText("." + int(9 - gameTimer.currentCount % 10).toString());
			gtField.setTextFormat(gtFieldFormat);
		}
		
		private function endGame( e:TimerEvent ) {
			holderGame.visible = false;
			holderScore.visible = true;
			scoreField.text = "WPM: " + score.toString();
			if( gameData.score == null ) {
				gameData.score = score.toString();
				scoreField.appendText('!');
				newTopScore(gameData.score.toString());
				minigameAPI.saveData();
			} else if ( int(gameData.score) < score ) {
				gameData.score = score.toString();
				scoreField.appendText('!');
				minigameAPI.saveData();
				newTopScore(gameData.score.toString());
			}
			scoreField.setTextFormat(scFieldFormat);
			gameRunning = false;
			btnSubmit.label = "Submit";
			btnSubmit.enabled = true;
			btnSubmit.addEventListener(MouseEvent.CLICK, submitScore);
		}
		
		private function submitScore( e:MouseEvent ) {
			btnSubmit.label = "Submitted!";
			minigameAPI.updateLeaderboard(leaderboard, score);
			btnSubmit.enabled = false;
			btnSubmit.removeEventListener(MouseEvent.CLICK, submitScore);
		}
		
		/*private function changeCountdown( e:TimerEvent ) {
			countField.text = int(3-ctTimer.currentCount).toString();
			countField.setTextFormat(ctFieldFormat);
			minigameAPI.log("[changeCountdown] - " + int(3-ctTimer.currentCount).toString());
		}
		
		private function startCount( e:MouseEvent ) {
			holderMain.visible = false;
			ctTimer.start();
			countField.text = int(3-ctTimer.currentCount).toString();
			countField.setTextFormat(ctFieldFormat);
			countField.visible = true;
			minigameAPI.log("[startCount]");
		}*/
		
		private function keyHit(e:KeyboardEvent){
			if( !gameRunning ) return;
			if( awaitKey ) {
				gameTimer.start();
				awaitKey = false;
			}
			
			//minigameAPI.log("[e.charCode == " + e.charCode + "]");
			if( e.charCode == 32 ) { // SPACE key
				vText[currentWord].background = false;
				if( vString[currentWord]!=buffWord ) vText[currentWord].textColor = failColor;
					else { vText[currentWord].textColor = goodColor; score++; }
				currentWord++;
				buffWord = "";
				vText[currentWord].background = true;
				vText[currentWord].backgroundColor = selColor;
				if( vText[currentWord].y > startRow ) shiftRow();
			} else  if( e.keyCode == Keyboard.BACKSPACE ) { // BACKSPACE key
				buffWord = buffWord.substr(0, buffWord.length-1);
				if( vString[currentWord].substr(0, buffWord.length)!=buffWord ) vText[currentWord].textColor = failColor;
					else vText[currentWord].textColor = normColor;
			} else if( (e.charCode>96 && e.charCode<123) || e.charCode == 39 ){ // ALPHABET keys
				buffWord = buffWord + String.fromCharCode(e.charCode);
				if( vString[currentWord].substr(0, buffWord.length)!=buffWord ) vText[currentWord].textColor = failColor;
					else vText[currentWord].textColor = normColor;
			}
			
			inputField.text = buffWord;
			inputField.setTextFormat(inFieldFormat);
		}
		
		private function shiftRow() {
			holderText.y -= vText[currentWord].y - vText[currentWord-1].y;
			for( var i:int = 1; i < 15; i++ ) {
				if( currentWord - i >= 0 ) vText[currentWord-i].visible = false;
			}
			startRow = vText[currentWord].y;
		}

		public override function initialize() : void {
			var buttonClass:Class = getDefinitionByName("ButtonThinSecondary") as Class;
			var scrButtonClass:Class = getDefinitionByName("chrome_button_normal") as Class;
			var resButtonClass:Class = getDefinitionByName("ButtonSkinned") as Class;
			var btnStart:MovieClip = new buttonClass();
			var btnRetry:MovieClip = new scrButtonClass();
			var btnQuit:MovieClip = new scrButtonClass();
			var btnRes:MovieClip = new resButtonClass();
			btnSubmit = new scrButtonClass();
			 
			btnRes.label = "Reset";
			btnRes.x = 280;
			btnRes.y = 5;
			btnStart.label = "Start";
			btnStart.x = 150;
			btnStart.y = 100;
			
			btnSubmit.label = "Submit";
			btnRetry.label = "Retry";
			btnQuit.label = "Quit";
			btnSubmit.x = 180;
			btnSubmit.y = 100;
			btnRetry.x = 180;
			btnRetry.y = 125;
			btnQuit.x = 180;
			btnQuit.y = 150;

			maskTxt.graphics.lineStyle();
			maskTxt.graphics.beginFill(0x000000,1);
			maskTxt.graphics.drawRect(0,0,380,45);
			maskTxt.graphics.endFill();
			
			maskTxt.x = 10;
			maskTxt.y = 75;
			
			this.addChild(holderMain);
			holderMain.addChild(btnStart);
			this.addChild(holderGame);
			holderGame.addChild(holderText);
			holderGame.addChild(maskTxt);
			holderGame.addChild(btnRes);
			holderText.mask = maskTxt;
			this.addChild(holderScore);
			holderScore.addChild(btnSubmit);
			holderScore.addChild(btnRetry);
			holderScore.addChild(btnQuit);
			
			setInputField();
			//setCountField();
			setGtField();
			setScoreField();
			
			gameTimer = new Timer(100, 600);
			gameTimer.addEventListener(TimerEvent.TIMER_COMPLETE, endGame);
			gameTimer.addEventListener(TimerEvent.TIMER, changeGameCountdown);
			
			/*ctTimer = new Timer(1000, 3);
			ctTimer.addEventListener(TimerEvent.TIMER_COMPLETE, startGame);
			ctTimer.addEventListener(TimerEvent.TIMER, changeCountdown);*/
			
			holderGame.visible = false;
			holderScore.visible = false;
			
			btnStart.addEventListener(MouseEvent.CLICK, startGame);
			btnRetry.addEventListener(MouseEvent.CLICK, startGame);
			btnRes.addEventListener(MouseEvent.CLICK, startGame);
			btnQuit.addEventListener(MouseEvent.CLICK, quit);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHit);
			
			loadWords();
			
			gameData = minigameAPI.getData();
			
			setTopScoreField();
			if( gameData.score != null ) newTopScore(gameData.score.toString());
				else newTopScore("-");
			
			minigameAPI.resizeGameWindow(winW, winH);
		}
		
		private function loadWords() {
			wordList.push("time", "person", "year", "way", "day", "thing", "man", "world", "life", "hand", "part", "child", "eye", "woman", "place", "work", "week", "case", "point", "government", "company", "number", "group", "problem", "fact", "be", "have", "do", "say", "get", "make", "go", "know", "take", "see", "come", "think", "look", "want", "give", "use", "find", "tell", "ask", "seem", "feel", "try", "leave", "call", "good", "new", "first", "last", "long", "great", "little", "own", "other", "old", "right", "big", "high", "different", "small", "large", "next", "early", "young", "important", "few", "public", "bad", "same", "able", "to", "of", "in", "for", "on", "with", "at", "by", "from", "up", "about", "into", "over", "after", "beneath", "under", "above", "others", "the", "and", "that", "not", "he", "as", "you", "this", "but", "his", "they", "her", "she", "or", "an", "will", "my", "one", "all", "would", "there", "their", "axe", "disruptor", "research", "quelling", "blade", "sword", "scheme", "roll", "frequent", "love", "mind", "abaddon", "alchemist", "bane", "batrider", "bloodseeker", "beastmaster", "bounty", "hunter", "ancient", "creep", "jungle", "gold", "cyka", "bristleback", "broodmother", "centaur", "chaos", "knight", "chen", "clinkz", "clockwerk", "crystal", "maiden", "dazzle", "death", "prophet", "doom", "dragon", "drow", "ranger", "earth", "spirit", "storm", "earthshaker", "elder", "titan", "ember", "enchantress", "enigma", "faceless", "void", "gyrocopter", "huskar", "invoker", "io", "jakiro", "juggernaut", "keeper", "light", "kunkka", "agility", "intelligence", "strength", "legion", "commander", "leshrac", "lich", "lina", "lion", "lone", "druid", "lifestealer", "luna", "mirana", "lycan", "magnus", "medusa", "meepo", "morphling", "naga", "siren", "nature's", "necrophos", "night", "stalker", "nyx", "assassin", "ogre", "magi", "omniknight", "oracle", "outworld", "devourer", "phantom", "phoenix", "puck", "pudge", "pugna", "queen", "pain", "razor", "riki", "rubick", "sand", "king", "shadow", "demon", "fiend", "silencer", "shaman", "skywrath", "mage", "slardar", "slark", "sniper", "spectre", "breaker", "sven", "techies", "templar", "terrorblade", "tidehunter", "timbersaw", "tinker", "treant", "protector", "tusk", "undying", "ursa", "venomancer", "viper", "visage", "warlock", "windranger", "winter", "wyvern", "witch", "doctor", "wraith", "zeus", "evil", "geniuses", "secret", "vici", "gaming", "alliance", "natus", "vincere");
		}
		
		private function newTopScore(s:String) {
			topScoreField.text = "Top WPM: "+s;
			topScoreField.setTextFormat(topScoreFieldFormat);
		}
		
		private function setTopScoreField() {
			var txFormat:TextFormat = new TextFormat();

			txFormat.color = "0xFFFFFF"
			txFormat.size = 30;
			//txFormat.font = "$TitleFont"
			txFormat.align = "center";
			topScoreFieldFormat = txFormat;
			topScoreField.autoSize = "center";
			topScoreField.multiline = false;
			topScoreField.wordWrap = false;
			topScoreField.text = "Top WPM: -";
			topScoreField.background = false;
			topScoreField.selectable = false;
			topScoreField.x = 190;
			topScoreField.y = 25;
			topScoreField.setTextFormat(topScoreFieldFormat);
			
			holderMain.addChild(topScoreField);
		}
		
		private function setScoreField() {
			var txFormat:TextFormat = new TextFormat();

			txFormat.color = "0xFFFFFF"
			txFormat.size = 30;
			//txFormat.font = "$TitleFont"
			txFormat.align = "center";
			scFieldFormat = txFormat;
			scoreField.autoSize = "center";
			scoreField.multiline = false;
			scoreField.wordWrap = false;
			scoreField.text = "WPM: 121";
			scoreField.background = false;
			scoreField.selectable = false;
			scoreField.x = 200-scoreField.width/2;
			scoreField.y = 25;
			scoreField.setTextFormat(scFieldFormat);
			
			holderScore.addChild(scoreField);
		}
		
		private function setGtField() {
			var txFormat:TextFormat = new TextFormat();

			txFormat.color = "0xFFFFFF"
			txFormat.size = 30;
			//txFormat.font = "$TitleFont"
			txFormat.align = "center";
			gtFieldFormat = txFormat;
			gtField.autoSize = "center";
			gtField.multiline = false;
			gtField.wordWrap = false;
			gtField.text = "60.0";
			gtField.background = false;
			gtField.selectable = false;
			gtField.x = 200-gtField.width/2;
			gtField.y = 25;
			gtField.setTextFormat(gtFieldFormat);
			
			holderGame.addChild(gtField);
		}
		
		/*private function setCountField() {
			var txFormat:TextFormat = new TextFormat();

			txFormat.color = "0xFFFFFF"
			txFormat.size = 50;
			//txFormat.font = "$TitleFont"
			txFormat.align = "center";
			ctFieldFormat = txFormat;
			countField.autoSize = "center";
			countField.multiline = false;
			countField.wordWrap = false;
			countField.text = "3";
			countField.background = false;
			countField.selectable = false;
			countField.x = 200-countField.width/2;
			countField.y = 150-countField.height/2;
			countField.setTextFormat(ctFieldFormat);
			
			this.addChild(countField);
			countField.visible = false;
		}*/
		
		private function setInputField() {
			var txFormat:TextFormat = new TextFormat();

			txFormat.color = "0xFFFFFF"
			txFormat.size = 24;
			//txFormat.font = "$TitleFont"
			txFormat.align = "center";
			inFieldFormat = txFormat;
			inputField.autoSize = "center";
			inputField.multiline = false;
			inputField.wordWrap = false;
			inputField.width = 100;
			inputField.text = "";
			inputField.background = true;
			inputField.backgroundColor = 0x303030;
			inputField.selectable = false;
			inputField.x = 200;
			inputField.y = 130;
			inputField.setTextFormat(inFieldFormat);
			
			holderGame.addChild(inputField);
		}
		
		private function addWord( buff:String ) {
			var txFormat:TextFormat = new TextFormat();
			var txField:TextField = new TextField;

			txFormat.color = "0xFFFFFF"
			txFormat.size = 18;
			//txFormat.font = "$TitleFont"
			txFormat.align = "left";
			
			txField.autoSize = "left";
			txField.multiline = false;
			txField.wordWrap = false;
			txField.text = buff;
			txField.background = false;
			txField.selectable = false;
			
			txField.setTextFormat(txFormat);
			
			if(vText.length == 0 ) {
				txField.x = 10;
				txField.y = 0;
				buffY = 0;
			} else if(vText[vText.length-1].x + vText[vText.length-1].width + 5 + txField.width > winW-10 ) {
				txField.x = 10;
				txField.y = vText[vText.length-1].y + 20;
				spaceFields(buffY, vText.length-1);
				buffY = vText.length;
			} else {
				txField.x = vText[vText.length-1].x + vText[vText.length-1].width + 5;
				txField.y = vText[vText.length-1].y;
			}
			
			holderText.addChild(txField);
			vText.push(txField);
		}
		
		private function spaceFields(bot:int, top:int) {
			var buff:Number = -5;
			var i:int;
			for( i = 0; i <= top-bot; i++ ) {
				buff+=vText[bot+i].width + 5;
			}
			vText[bot].x = (400-buff) / 2;
			
			for( i = 1; i <= top-bot; i++ ) {
				vText[bot+i].x = vText[bot+i-1].x + vText[bot+i-1].width + 5;
			}
		}
		
		private function populateText() {
			var rollingWord:Vector.<String> = new Vector.<String>;
			var randNum:int;
			while( vString.length < 300 ) {
				randNum = Math.floor(Math.random() * 263);
				if( rollingWord.indexOf(wordList[randNum])<0 ) {
					vString.push(wordList[randNum]);
					rollingWord.push(wordList[randNum]);
					if( rollingWord.length>5 ) rollingWord.shift();
				}
			}
		}
		
		private function quit() {
			if( gameTimer != null ) gameTimer.stop();
			minigameAPI.closeMinigame();
		}
		
		public override function close() : Boolean{
			if( gameTimer != null ) gameTimer.stop();
			return true;
		}
		
		public override function resize(stageWidth:int, stageHeight:int, scaleRatio:Number) : Boolean{
			return true;
		}
	}
}
