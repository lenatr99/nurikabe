var groupsArray;
var wallGroupsArray;
var guessCount = 0;
var guessSolveCount = 0;
var solveCount = 0;
var difficulty;
var genPuzzleState;
var invalidNumber = false;
var invalidGuess = false;
var invalidX;
var invalidY;
onmessage = function(e) {
	var params = e.data.split("_");
	if(params[0] == "generate"){
		console.log("STARTING GENERATION");
		generator = new generateObject(params[1], params[2], params[3], params[4]);
		genPuzzle = generator.generate();
		while(genPuzzle == "none"){
			console.log("STARTING GENERATION");
			generator = new generateObject(params[1], params[2], params[3], params[4]);
			genPuzzle = generator.generate();
		}
		postMessage("done_" + genPuzzle);
	}else{
		solver = new solveObject(params[1], params[2]);
		solver.solve();
		postMessage("done_" + solver.getSolution());
	}
}


function solveObject(puzzleString, diff){
	this.difficulty = diff;
	var puzzle = new puzzleObject(puzzleString);
	this.puzzleState = puzzle.getPuzzleState();

	this.width = puzzle.getWidth();
	this.height = puzzle.getHeight();
	groupsArray = new Array();
	wallGroupsArray = new Array();
	if (this.difficulty == ("easy")){
		this.guessDepth = 0;
		this.guessLimit = 0;
	}else if (this.difficulty == ("medium")){
		this.guessDepth = 0;
		this.guessLimit = 0;
	}else if (this.difficulty == ("hard")){
		this.guessDepth = 1;
		this.guessLimit = 3;
	}else if (this.difficulty == ("harder")){
		this.guessDepth = 10;
		this.guessLimit = 10;
	}else if (this.difficulty == ("max")){
		this.guessDepth = 20;
		this.guessLimit = 20;
	}
	
	solveObject.prototype.solve = function(){
		solveCount = 0;
		guessCount = 0;

		createGroups(this.width, this.height, this.puzzleState);
		//console.log(groupsArray);
		for (var x=0;x < (this.height);x++) {
			for (var y=0; y < (this.width);y++) {

			}
		}
		solveLogic(this.width, this.height, this.puzzleState, groupsArray, solveCount, this.difficulty, this.guessDepth, this.guessLimit, false);
		var solution = "";
		var solved = "true";
		//if(JSON.stringify(this.puzzleState).indexOf("-") != -1){
		//	solved = "false";
		//}

		var wallCount = 0;
		var emptyCount = 0;
		var numberTotal = 0;
		for (var x=0;x < (this.height);x++) {
			for (var y=0; y < (this.width);y++) {
				//alert(puzzleState[x][y]);
				solution += this.puzzleState[x][y] + ",";
				if(this.puzzleState[x][y] == ("-")){
					solved = "false";
					emptyCount++;
				}else if(this.puzzleState[x][y] == ("#")){
					wallCount++;
				}else if(Number.isInteger(this.puzzleState[x][y] * 1)){
					numberTotal += this.puzzleState[x][y] * 1;
				}else if(this.puzzleState[x][y] == ("*")){
					emptyCount++;
				}
			}
		}
		if(checkBlock(this.puzzleState, 0, 0, this.width, this.height) == true){
			solved = "false";
		}
		if(solved == "true"){
			if(wallCount > (this.width * this.height) - numberTotal){
				//console.log("AAAHHH");
				//console.log(wallCount + " " + emptyCount + " " + numberTotal);
				solved = "false";
			}
		}
		if(solved == "true"){
			loop1:
			for (var x2=0;x2 < (this.height);x2++) {
				loop2:
				for (var y2=0; y2 < (this.width);y2++) {
					if(this.puzzleState[x2][y2] == "#"){
						visitedWalls = travelCells(this.width, this.height, x2, y2, this.puzzleState, "#");
						break loop2;
						//visitedWallCells.push.apply(visitedWallCells, visitedWalls);
						//wallGroups.push(visitedWalls);
					}
				}
			}
			//console.log(visitedWalls);
			for (var x=0;x < (this.height);x++) {
				for (var y=0; y < (this.width);y++) {
					if(this.puzzleState[x][y] == "#" && visitedWalls.indexOf(x + "-" + y) == -1){
						solved = "false";
					}
				}
			}

		}
		//console.log(groupsArray);

		this.solutionString = solved + ":" + solveCount + ":" + solution;
		
	}
	solveObject.prototype.getSolution = function(){
		return this.solutionString;
	}
}
function generateObject(w, h, difficultySetting, symmetrySetting) {
	this.height = h;
	this.width = w;
	height = h
	width = w;
	this.difficulty = difficultySetting;
	this.tempDifficulty = difficultySetting;
	this.puzzleString = "";
	this.genPuzzleState = new Array(this.height);
	for(var i=0;i<this.height;i++){
		this.genPuzzleState[i] = new Array(this.width);
	}

	generateObject.prototype.generate = function(){
		var minimumSolvedCount = (this.width * 1 * this.height * 1) / 100;
		var isValidGrid = true;
		var gridRegenCount = 0;
		if(this.difficulty != "medium" && this.difficulty != "easy"){
			this.tempDifficulty = "medium";
		}
		var temp = generateGrid(this.genPuzzleState, this.tempDifficulty, this.width, this.height);
		this.genPuzzleState = generateNumbers(this.genPuzzleState, this.tempDifficulty, this.width, this.height);
		var puzzleString = generatePuzzleString(this.genPuzzleState, this.width, this.height);
		var solver = new solveObject(puzzleString, this.tempDifficulty);
		solver.solve();
		var temp = solver.getSolution().split(":");
		var solution = temp[2];

		//var textState = JSON.stringify(this.genPuzzleState);
		//console.log(textState);
		var wallCount = (solution.match(/#/g)||[]).length;
		var solvedCount = wallCount + (solution.match(/\*/g)||[]).length;
		if(solvedCount < minimumSolvedCount){
			isValidGrid = false;
		}
		//var isValidGrid = temp[0];
		console.log(puzzleString);
		
		while(isValidGrid == false){
			gridRegenCount++;
			this.genPuzzleState = new Array(this.height);
			for(var h=0;h<this.height;h++){
				this.genPuzzleState[h] = new Array(this.width);
			}
			var temp = generateGrid(this.genPuzzleState, this.tempDifficulty, this.width, this.height);
			this.genPuzzleState = generateNumbers(this.genPuzzleState, this.tempDifficulty, this.width, this.height);
			var puzzleString = generatePuzzleString(this.genPuzzleState, this.width, this.height);
			console.log(puzzleString);
			var solver = new solveObject(puzzleString, this.tempDifficulty);
			solver.solve();
			var temp = solver.getSolution().split(":");
			var solution = temp[2];

			//var textState = JSON.stringify(this.genPuzzleState);
			//console.log(solution);
			var wallCount = (solution.match(/#/g)||[]).length;
			var solvedCount = wallCount + (solution.match(/\*/g)||[]).length;
			//console.log(wallCount);
			postMessage("value_" + solvedCount);
			if(solvedCount < minimumSolvedCount){
				isValidGrid = false;
			}else{
				isValidGrid = true;
			}
			
			//isValidGrid = temp[0];
			if(isValidGrid == false){
				console.log("regen");
				postMessage("regen");
			}
			//console.log(isValidGrid);
		}
		var regenCount = 0;
		//this.genPuzzleState = generateNumbers(this.genPuzzleState, this.difficulty, this.width, this.height);
		//this.genPuzzleState = removeWalls(this.genPuzzleState, this.difficulty, this.width, this.height);
		var puzzleString = generatePuzzleString(this.genPuzzleState, this.width, this.height);
		var solver = new solveObject(puzzleString, this.tempDifficulty);
		solver.solve();
		var temp = solver.getSolution().split(":");
		var isSolvable = temp[0];
		var solution = temp[2];
		//console.log(isSolvable);
		//isSolvable = "false";
		var wallCount = (solution.match(/#/g)||[]).length;
		var solvedCount = wallCount + (solution.match(/\*/g)||[]).length;
		while(isSolvable == "false"){

			var nextAction = "add"
			if(regenCount > 11){
				break;
			}
			var oldGenPuzzleState = JSON.parse(JSON.stringify(this.genPuzzleState));
			var oldSolvedCount = solvedCount;

			if(nextAction == "remove"){
				this.genPuzzleState = removeWalls(this.genPuzzleState, this.tempDifficulty, this.width, this.height);
			}else{
				this.genPuzzleState = addWalls(this.genPuzzleState, this.tempDifficulty, this.width, this.height);
			}
			/*
			if(regenCount % 2 == 0){
				this.genPuzzleState = removeWalls(this.genPuzzleState, this.difficulty, this.width, this.height);
			}else{
				this.genPuzzleState = addWalls(this.genPuzzleState, this.difficulty, this.width, this.height);
			}*/

			this.genPuzzleState = generateNumbers(this.genPuzzleState, this.tempDifficulty, this.width, this.height);
			var puzzleString = generatePuzzleString(this.genPuzzleState, this.width, this.height);
			var solver = new solveObject(puzzleString, this.tempDifficulty);
			solver.solve();
			var temp = solver.getSolution().split(":");
			isSolvable = temp[0];
			var solution = temp[2];
			//console.log(isSolvable);
			//isSolvable = "false";
			var wallCount = (solution.match(/#/g)||[]).length;
			var solvedCount = wallCount + (solution.match(/\*/g)||[]).length;
			postMessage("value_" + solvedCount);

			console.log("solved count " + solvedCount + " " + wallCount);
			
			if(oldSolvedCount > solvedCount + 20){
				solvedCount = oldSolvedCount;
				if(isSolvable == "false"){
					this.genPuzzleState = JSON.parse(JSON.stringify(oldGenPuzzleState));
					if(nextAction == "add"){
						nextAction = "remove";
					}
				}
			}else{

				//nextAction = "add";
				if(nextAction == "remove"){
					nextAction = "add";
				}else{
					nextAction = "remove"
				}
			}

			regenCount++;
		}
		if(isSolvable == "true"){
			postMessage("reset_" + wallCount * 5);
			if(this.difficulty != "medium" && this.difficulty != "easy"){
				//console.log("WHAT");
				this.tempDifficulty = this.difficulty + "";
			}else{
				//console.log(this.tempDifficulty);
			}
			var refactorCount = 0;
			var refactorLimit = 100;
			var failedRefactor = 0;
			while(refactorCount < refactorLimit && failedRefactor < 3){
				var oldGenPuzzleState = JSON.parse(JSON.stringify(this.genPuzzleState));
				var states = new Array();
				states = refactorGrid(oldGenPuzzleState, this.tempDifficulty, this.width, this.height);
				if(states.length > 0){
					console.log(states);
					this.genPuzzleState = JSON.parse(JSON.stringify(states[states.length - 1]));
					console.log(this.genPuzzleState);
					
					//failedRefactor = 0;
				}else{

					//this.genPuzzleState = JSON.parse(JSON.stringify(oldGenPuzzleState));
					var logPuzzleString = generatePuzzleString(this.genPuzzleState, this.width, this.height);
					console.log("no changes");
					console.log(logPuzzleString);
					failedRefactor++;
				}

				refactorCount++;
			}
			console.log(this.genPuzzleState);
			//tries other positions of numbers to tweak difficulty

			var logPuzzleString = generatePuzzleString(this.genPuzzleState, this.width, this.height);
			console.log("before modify");
			console.log(logPuzzleString);
			this.genPuzzleState = modifyDifficulty(this.genPuzzleState, this.tempDifficulty, this.width, this.height);

			
		}



		//console.log(this.genPuzzleState);
		//this.genPuzzleState = removeWalls(this.genPuzzleState, this.difficulty, this.width, this.height);
		//this.genPuzzleState = generateNumbers(this.genPuzzleState, this.difficulty, this.width, this.height);
		var finalPuzzleString = generatePuzzleString(this.genPuzzleState, this.width, this.height);

		console.log(regenCount);
		console.log(gridRegenCount);
		console.log(refactorCount);
		console.log(finalPuzzleString);
		var solver = new solveObject(finalPuzzleString, this.difficulty);
		solver.solve();
		var temp = solver.getSolution().split(":");
		var isSolvable = temp[0];
		if(isSolvable == "false"){
			finalPuzzleString = "none";
		}
		return finalPuzzleString;
	}
}

function generatePuzzleString(stringState, width, height){
	var puzzleString = width + "x" + height + ":";
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			if(stringState[x][y] != "-" && stringState[x][y] != "#"){
				puzzleString += stringState[x][y] + ",";
			}else{
				puzzleString += "-,";
			}
		}
	}
	//puzzleString = puzzleString.substring(0, puzzleString.length - 1);
	return puzzleString;
}
function modifyDifficulty(modifyState, difficulty, width, height){
	console.log("modifying difficulty");
	var newModifyState = new Array();
	for (var x=0;x < (height);x++) {
		newModifyState[x] = new Array();
		for (var y=0; y < (width);y++) {
			newModifyState[x][y] = modifyState[x][y] + "";
			if(newModifyState[x][y] != "#"){
				newModifyState[x][y] = "-";
			}
		}
	}
	var genGroups = new Array();
	var visitedEmptyCells = new Array();
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			if(modifyState[x][y] == "-" && visitedEmptyCells.indexOf(x + "-" + y) == -1){
				var visitedCells = travelCells(width, height, x, y, newModifyState, "-");
				visitedEmptyCells.push.apply(visitedEmptyCells, visitedCells);
				genGroups.push(visitedCells);
			}
		}
	}
	//console.log(genGroups);
	for (var i = 0; i < genGroups.length; i++) {
		genGroups[i] = shuffle(genGroups[i]);
		var solveLengths = new Array();
		
		var oldNumberLocation = "";
		for(var j = 0; j < genGroups[i].length; j++){
			var temp = genGroups[i][j].split("-");
			var oldX = temp[0] * 1;
			var oldY = temp[1] * 1;
			if(modifyState[oldX][oldY] == genGroups[i].length){
				oldNumberLocation = genGroups[i][j];
				modifyState[oldX][oldY] = "-";
			}
		}
		for(var j = 0; j < genGroups[i].length; j++){
			if(genGroups[i].length > 1){
				var temp = genGroups[i][j].split("-");
				var numberX = temp[0] * 1;
				var numberY = temp[1] * 1;
				modifyState[numberX][numberY] = genGroups[i].length + "";
				var puzzleString = generatePuzzleString(modifyState, width, height);
				//console.log(puzzleString);
				var solver = new solveObject(puzzleString, difficulty);
				solver.solve();
				var temp = solver.getSolution().split(":");
				var isModifySolvable = temp[0];
				var modifySolveCount = temp[1];
				if(isModifySolvable == "true"){
					solveLengths.push(numberX + "-" + numberY + "-" + modifySolveCount);
				}
				modifyState[numberX][numberY] = "-";
			}
		}
		solveLengths = shuffle(solveLengths);
		solveLengths.sort(function(a, b) {
			var temp = a.split("-");
			var aCount = temp[2] * 1;
			var temp = b.split("-");
			var bCount = temp[2] * 1;
			return bCount - aCount; 
		});

		//var adjacentNumberCounts = new Array();
		if(solveLengths.length > 0){
			var temp = solveLengths[0].split("-");
			var numberX = temp[0] * 1;
			var numberY = temp[1] * 1;
		}else{
			var temp = oldNumberLocation.split("-");
			var numberX = temp[0] * 1;
			var numberY = temp[1] * 1;
		}
		modifyState[numberX][numberY] = genGroups[i].length + "";
	}
	return modifyState;
}
function removeWalls(removeGenState, difficulty, width, height){
	
	var walls = new Array();
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			if(removeGenState[x][y] == "#"){
				walls.push(x + "-" + y);
			}
		}
	}
	walls = shuffle(walls);
	for (var i = 0; i < walls.length; i++) {
		var temp = walls[i].split("-");
		var removeX = temp[0] * 1;
		var removeY = temp[1] * 1;
		removeGenState[removeX][removeY] = "-";
		var visitedWalls = new Array();
		var separateWalls = false;
		
		loop1:
		for (var x=0;x < (height);x++) {
			loop2:
			for (var y=0; y < (width);y++) {
				if(removeGenState[x][y] == "#"){
					visitedWalls = travelCells(width, height, x, y, removeGenState, "#");
					break loop2;
					//visitedWallCells.push.apply(visitedWallCells, visitedWalls);
					//wallGroups.push(visitedWalls);
				}
			}
		}
		//console.log(visitedWalls);
		for (var x=0;x < (height);x++) {
			for (var y=0; y < (width);y++) {
				if(removeGenState[x][y] == "#" && visitedWalls.indexOf(x + "-" + y) == -1){
					separateWalls = true;
				}
			}
		}
		if(separateWalls == false){
			var chanceOfRemove = Math.floor((Math.random()*3));
			//chanceOfRemove = 1;
			if(chanceOfRemove == 1){
				//console.log("removing " + removeX + "-" + removeY);
			}else{
				removeGenState[removeX][removeY] = "#";
			}
		}else{
			removeGenState[removeX][removeY] = "#";
		}
	}
	return removeGenState;
}
function addWalls(addGenState, difficulty, width, height){
	var cellsArray = new Array();
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			if(addGenState[x][y] != "#" && addGenState != "*"){
				var adjacentWall = false;
				if(x != 0 && addGenState[x - 1][y] == "#"){
					adjacentWall = true;
				}else if(x != height - 1 && addGenState[x + 1][y] == "#"){
					adjacentWall = true;
				}else if(y != 0 && addGenState[x][y - 1] == "#"){
					adjacentWall = true;
				}else if(y != width - 1 && addGenState[x][y + 1] == "#"){
					adjacentWall = true;
				}
				var chanceOfAdd = Math.floor((Math.random()*3));
				if(chanceOfAdd == 1){
					if(checkBlock(addGenState, x, y, width, height) == false){
						//console.log("adding");
						addGenState[x][y] = "#";
					}
				}
			}
		}
	}
	return addGenState;
}
function refactorGrid(refactorGenState, difficulty, width, height){
	console.log("starting refactor " + difficulty);
	
	var validStates = new Array();
	var walls = new Array();
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			if(refactorGenState[x][y] == "#"){
				var oneCount = 0;
				
				if(x != 0 && refactorGenState[x - 1][y] == "1"){
					oneCount++;
				}
				if(x == 0){
					oneCount+= .5;
				}
				if(x != height - 1 && refactorGenState[x + 1][y] == "1"){
					oneCount++;
				}
				if(x == height - 1){
					oneCount+= .5;
				}
				if(y != 0 && refactorGenState[x][y - 1] == "1"){
					oneCount++;
				}
				if(y == 0){
					oneCount+= .5;
				}
				if(y != width - 1 && refactorGenState[x][y + 1] == "1"){
					oneCount++;
				}
				if(y == width - 1){
					oneCount+= .5;
				}
				walls.push(x + "-" + y + "-" + oneCount);
			}
		}
	}
	walls = shuffle(walls);
	walls.sort(function(a, b) {
		var temp = a.split("-");
		var aCount = temp[2] * 1;
		var temp = b.split("-");
		var bCount = temp[2] * 1;
		return bCount - aCount; 
	});
	for (var i = 0; i < walls.length; i++) {
		var temp = walls[i].split("-");
		var removeX = temp[0] * 1;
		var removeY = temp[1] * 1;
		refactorGenState[removeX][removeY] = "-";
		var visitedWalls = new Array();
		var separateWalls = false;
		
		loop1:
		for (var x2=0;x2 < (height);x2++) {
			loop2:
			for (var y2=0; y2 < (width);y2++) {
				if(refactorGenState[x2][y2] == "#"){
					visitedWalls = travelCells(width, height, x2, y2, refactorGenState, "#");
					break loop2;
					//visitedWallCells.push.apply(visitedWallCells, visitedWalls);
					//wallGroups.push(visitedWalls);
				}
			}
		}
		//console.log(visitedWalls);
		for (var x=0;x < (height);x++) {
			for (var y=0; y < (width);y++) {
				if(refactorGenState[x][y] == "#" && visitedWalls.indexOf(x + "-" + y) == -1){
					separateWalls = true;
				}
			}
		}
		if(separateWalls == false){
			//console.log(removeX + "-" + removeY);
			var oldRefactorGenState = new Array();
			for (var x=0;x < (height);x++) {
				oldRefactorGenState[x] = new Array();
				for (var y=0; y < (width);y++) {
					oldRefactorGenState[x][y] = refactorGenState[x][y] + "";
					if(oldRefactorGenState[x][y] != "#"){
						oldRefactorGenState[x][y] = "-";
					}
				}
			}
			
			var newEmptyGroupCells = travelCells(width, height, removeX, removeY, oldRefactorGenState, "-");
			newEmptyGroupCells = shuffle(newEmptyGroupCells);
			var previousNumberX;
			var previousNumberY;
			var tempRefactorGenState = generateNumbers(refactorGenState, difficulty, width, height);
			for (var i3 = 0; i3 < newEmptyGroupCells.length; i3++) {
				var temp = newEmptyGroupCells[i3].split("-");
				var tempX = temp[0] * 1;
				var tempY = temp[1] * 1;
				//if (tempRefactorGenState[tempX][tempY] != "-"){
					previousNumberX = tempX * 1;
					previousNumberY = tempY * 1;
					tempRefactorGenState[tempX][tempY] = "-";
				//}
			}
			var foundSolvable = false;
			var testCount = 0;
			for (var i3 = 0; i3 < newEmptyGroupCells.length; i3++) {
				if(testCount < 30 && foundSolvable == false){
					var temp = newEmptyGroupCells[i3].split("-");
					var tempRefactorX = temp[0] * 1;
					var tempRefactorY = temp[1] * 1;
					tempRefactorGenState[tempRefactorX][tempRefactorY] = newEmptyGroupCells.length + "";
					var puzzleString = generatePuzzleString(tempRefactorGenState, width, height);
					//console.log(puzzleString);
					var solver = new solveObject(puzzleString, difficulty);
					solver.solve();
					var temp = solver.getSolution().split(":");
					var isSolvable = temp[0];
					if(isSolvable == "true"){
						foundSolvable = true;
						
						console.log(puzzleString);
						//console.log(tempRefactorGenState);
						//console.log(tempRefactorGenState);
						validStates.push(JSON.parse(JSON.stringify(tempRefactorGenState)));
						refactorGenState = JSON.parse(JSON.stringify(tempRefactorGenState));
						
						//refactorGenState = tempGenState;
						/*
						for (var x=0;x < (height);x++) {
							for (var y=0; y < (width);y++) {
								refactorGenState[x][y] = tempGenState[x][y];
							}
						}*/
						//console.log(refactorGenState);
					}
					if(tempRefactorX == previousNumberX && tempRefactorY == previousNumberY){
						tempRefactorGenState[tempRefactorX][tempRefactorY] = newEmptyGroupCells.length + "";
					}else{
						tempRefactorGenState[tempRefactorX][tempRefactorY] = "-";
					}
				}
				testCount++;
			}

			if(foundSolvable == false){
				refactorGenState[removeX][removeY] = "#";
			}else{
				console.log("refactoring " + removeX + "-" + removeY);
			}
			
		}else{
			//console.log("could not remove wall at " + removeX + "-" + removeY);
			refactorGenState[removeX][removeY] = "#";
		}
		postMessage("refactoring");
	}
	//console.log(refactorGenState);
	//console.log(validStates);
	return validStates;
}
function generateGrid(genState, difficulty, width, height){
	for (var x=0;x < height;x++) {
		for (var y=0; y < width;y++) {
			genState[x][y] = "-";
		}
	}
	//start cell
	var x = Math.floor(Math.random()* height);
	var y = Math.floor(Math.random() * width);

	var generateCount = 0;
	var continueCells = new Array();
	var cellsArray = new Array();
	var continueGenerating = true;
	var lastDirection = "none";
	//var directions = ["up", "down", "left", "right"];

	while (continueGenerating == true){
		var directions = [];
		generateCount++;
		if(continueCells.indexOf(x + "-" + y) == -1){
			continueCells.push(x + "-" + y);
		}
		if(cellsArray.indexOf(x + "-" + y) == -1){
			cellsArray.push(x + "-" + y);
		}
		//console.log(x + "-" + y);
		//console.log(cellsArray);
		genState[x][y] = "#";
		if(generateCount > (width * height) * 10){
			continueGenerating = false;
		}
		if(cellsArray.length > (width * height) / 1.5){
			//continueGenerating = false;
		}
		
		var chanceOfRandomize = Math.floor((Math.random()*3));
		chanceOfRandomize = 0;
		if (chanceOfRandomize == 1) {
			continueCells = shuffle(continueCells);
			var newSeedCell = continueCells[0].split("-");
			x = newSeedCell[0] * 1;
			y = newSeedCell[1] * 1;
			oldX = "none";
			oldY = "none";
			lastDirection = "none";
		}
		var makingLoop = Math.floor((Math.random()*2));
		makingLoop = 0;
		if (x != 0) {
			if (cellsArray.indexOf((x - 1) + "-" + (y)) == -1) {
				if(checkBlock(genState, x - 1, y, width, height) == false){
					if(makingLoop == 0){
						if(cellsArray.indexOf((x - 2) + "-" + (y)) == -1){
							directions.push("up");
						}
					}else{
						directions.push("up");		
					}
				}
			}
		}
		if (x != height - 1) {
			if ((cellsArray.indexOf((x + 1) + "-" + (y)) == -1)) {
				if(checkBlock(genState, x + 1, y, width, height) == false){
					if(makingLoop == 0){
						if(cellsArray.indexOf((x + 2) + "-" + (y)) == -1){
							directions.push("down");
						}
					}else{
						directions.push("down");		
					}
				}
			}
		}
		if (y != 0) {
			if (cellsArray.indexOf((x) + "-" + (y - 1)) == -1) {
				if(checkBlock(genState, x, y - 1, width, height) == false){
					if(makingLoop == 0){
						if(cellsArray.indexOf(x + "-" + (y - 2)) == -1){
							directions.push("left");
						}
					}else{
						directions.push("left");		
					}
				}
			}
		}
		if (y != width - 1) {
			if (cellsArray.indexOf((x) + "-" + (y + 1)) == -1) {
				if(checkBlock(genState, x, y + 1, width, height) == false){
					if(makingLoop == 0){
						if(cellsArray.indexOf(x + "-" + (y + 2)) == -1){
							directions.push("right");
						}
					}else{
						directions.push("right");		
					}
				}
			}
		}
		var rand = Math.floor((Math.random()*directions.length));
		//postMessage(rand + "-" + directions.length);
		var direction = directions[rand];
		if(directions.length > 1 && continueCells.indexOf(x + "-" + y) == -1){
			continueCells.push(x + "-" + y);
		}
		if(directions.indexOf(lastDirection) != -1){
			rand = Math.floor((Math.random()*3));
			if(rand == 0){
				direction = lastDirection;
			}
		}
		//console.log(directions);
		if(direction == ("up")) {
			lastDirection = "up";
			x--;
		}else if(direction == ("down")) {
			lastDirection = "down";
			x++;
		}else if(direction == ("left")) {
			lastDirection = "left";
			y--;
		}else if(direction == ("right")) {
			lastDirection = "right";
			y++;
		}else{
			continueCells.splice(continueCells.indexOf(x + "-" + y), 1);
			continueCells = shuffle(continueCells);
			if(continueCells.length != 0){
				lastDirection = "none";
				var newSeedCell = continueCells[0].split("-");
				x = parseInt(newSeedCell[0]) * 1;
				y = parseInt(newSeedCell[1]) * 1;
				//console.log("continue shuffled");
				//postMessage(x + "-" + y);
			}else{
				continueGenerating = false;
			}
		}
	}
	var isValidGrid = true;
	return [isValidGrid, genState];
}
function checkBlock(puzzleState, x2, y2, width, height){
	//cells = cells.slice(0);
	var makesBlock = false;
	//cells.push(x + "-" + y);
	puzzleState[x2][y2] = "#";
	for (x3 = 0;x3 < height;x3++) {
		for (y3 = 0;y3 < width;y3++) {
			if(puzzleState[x3][y3] == "#"){
				if(x3 != height - 1 && y3 != width - 1){
					if(puzzleState[x3 + 1][y3] == "#" && puzzleState[x3][y3 + 1] == "#" && puzzleState[x3 + 1][y3 + 1] == "#"){
						makesBlock = true;
					}
				}
			}
		}
	}
	puzzleState[x2][y2] = "-"


	return makesBlock;
}
function generateNumbers(numbersGenState, difficulty, width, height){
	var oldGenState = new Array();
	for (var x=0;x < (height);x++) {
		oldGenState[x] = new Array();
		for (var y=0; y < (width);y++) {
			oldGenState[x][y] = numbersGenState[x][y] + "";
			if(numbersGenState[x][y] != "#"){
				numbersGenState[x][y] = "-";
			}
		}
	}
	var genGroups = new Array();
	var visitedEmptyCells = new Array();
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			if(numbersGenState[x][y] == "-" && visitedEmptyCells.indexOf(x + "-" + y) == -1){
				var visitedCells = travelCells(width, height, x, y, numbersGenState, "-");
				visitedEmptyCells.push.apply(visitedEmptyCells, visitedCells);
				genGroups.push(visitedCells);
			}
		}
	}
	//console.log(genGroups);
	for (var i = 0; i < genGroups.length; i++) {
		genGroups[i] = shuffle(genGroups[i]);
		var adjacentNumberCounts = new Array();

		for (var j = 0; j < genGroups[i].length; j++) {
			var foundOldNumber = false;
			var temp = genGroups[i][j].split("-");
			var numberX = temp[0] * 1;
			var numberY = temp[1] * 1;
			//puts number where number used to be if possible
			if(oldGenState[numberX][numberY] != "-"){
				//console.log("found old number");
				foundOldNumber = true;
				break;
			}
			var adjacentNumberCount = 0;
			if(numberX != 0 && numberY != 0){
				if(Number.isInteger(oldGenState[numberX - 1][numberY - 1] * 1)){
					adjacentNumberCount+=2;
				}
				if(oldGenState[numberX - 1][numberY - 1] == "-" && genGroups[i].indexOf((numberX - 1) + "-" + (numberY - 1)) == -1){
					adjacentNumberCount++;
				}
			}
			if(numberX != 0 && numberY != width - 1){
				if(Number.isInteger(oldGenState[numberX - 1][numberY + 1] * 1)){
					adjacentNumberCount+=2;
				}
				if(oldGenState[numberX - 1][numberY + 1] == "-" && genGroups[i].indexOf((numberX - 1) + "-" + (numberY + 1)) == -1){
					adjacentNumberCount++;
				}
			}
			if(numberX != height - 1 && numberY != 0){
				if(Number.isInteger(oldGenState[numberX + 1][numberY - 1] * 1)){
					adjacentNumberCount+=2;
				}
				if(oldGenState[numberX + 1][numberY - 1] == "-" && genGroups[i].indexOf((numberX + 1) + "-" + (numberY - 1)) == -1){
					adjacentNumberCount++;
				}
			}
			if(numberX != height - 1 && numberY != width - 1){
				if(Number.isInteger(oldGenState[numberX + 1][numberY + 1] * 1)){
					adjacentNumberCount+=2;
				}
				if(oldGenState[numberX + 1][numberY + 1] == "-" && genGroups[i].indexOf((numberX + 1) + "-" + (numberY + 1)) == -1){
					adjacentNumberCount++;
				}
			}
			if(numberX == 0){
				adjacentNumberCount++;
			}
			if(numberY == 0){
				adjacentNumberCount++;
			}
			if(numberX == height - 1){
				adjacentNumberCount++;
			}
			if(numberY == width - 1){
				adjacentNumberCount++;
			}
			adjacentNumberCounts.push(adjacentNumberCount + "-" + numberX + "-" + numberY);
		}
		if(foundOldNumber == false){
			adjacentNumberCounts.sort(function(a, b) {
				var temp = a.split("-");
				var aCount = temp[0] * 1;
				var temp = b.split("-");
				var bCount = temp[0] * 1;
				return bCount - aCount; 
			});
			//console.log(adjacentNumberCounts);
			var temp = adjacentNumberCounts[0].split("-");
			numberX = temp[1] * 1;
			numberY = temp[2] * 1;
		}
		//var temp = genGroups[i][0].split("-");
		//var numberX = temp[0] * 1;
		//var numberY = temp[1] * 1;
		numbersGenState[numberX][numberY] = genGroups[i].length + "";
	}
	return numbersGenState;
}
function createGroups(width, height, puzzleState){
	//finds all empty sections
	var visitedEmptyCells = new Array();
	var visitedEmptyGroups = new Array();
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			if(puzzleState[x][y] == "-" && visitedEmptyCells.indexOf(x + "-" + y) == -1){
				var visitedCells = travelCells(width, height, x, y, puzzleState, "-");
				visitedEmptyCells.push.apply(visitedEmptyCells, visitedCells);
				visitedEmptyGroups.push(visitedCells);
			}
		}
	}

	var allVisitedCells = new Array();
	for (x2=0;x2 < height;x2++) {
		for (y2=0; y2 < width;y2++) {
			if(puzzleState[x2][y2] != "-" && allVisitedCells.indexOf(x2 + "-" + y2) == -1){
				var groupNumber = puzzleState[x2][y2];
				var visitedCells = travelCells(width, height, x2, y2, puzzleState, groupNumber);
				allVisitedCells.push.apply(allVisitedCells, visitedCells);
				if(groupNumber == 1){
					isFinished = true;
				}else{
					isFinished = false;
				}
				
				var allEscapes = new Array();
				if(isFinished == false){
					for (var i = 0; i < visitedCells.length; i++) {
						var coords = visitedCells[i].split("-");
						var candsx = coords[0] * 1;
						var candsy = coords[1] * 1;
						if(visitedEmptyCells.indexOf((candsx + 1) + "-" + candsy) != -1){
							if(allEscapes.indexOf((candsx + 1) + "-" + candsy) == -1){
								allEscapes.push((candsx + 1) + "-" + candsy);
							}
						}
						if(visitedEmptyCells.indexOf((candsx - 1) + "-" + candsy) != -1){
							if(allEscapes.indexOf((candsx - 1) + "-" + candsy) == -1){
								allEscapes.push((candsx - 1) + "-" + candsy);
							}
						}
						if(visitedEmptyCells.indexOf(candsx + "-" + (candsy + 1)) != -1){
							if(allEscapes.indexOf(candsx + "-" + (candsy + 1)) == -1){
								allEscapes.push(candsx + "-" + (candsy + 1));
							}
						}
						if(visitedEmptyCells.indexOf(candsx + "-" + (candsy - 1)) != -1){
							if(allEscapes.indexOf(candsx + "-" + (candsy - 1)) == -1){
								allEscapes.push(candsx + "-" + (candsy - 1));
							}
						}
					}
				}
				var group = new groupObject(groupNumber, visitedCells, allEscapes, isFinished, false, groupsArray.length);
				groupsArray.push(group);
			}
		}
	}
}
function travelCells(width, height, xCoord, yCoord, travelPuzzleState, number){
	var visitedCells = new Array();
	var x = xCoord;
	var y = yCoord;
	var continueTraveling = true;
	var multiNumbers = number.split(",");
	var notWalls = false;
	if(multiNumbers == "notwalls"){
		notWalls = true;
	}
	//console.log(multiNumbers);
	if(notWalls == true){
		while(continueTraveling == true){
			if (visitedCells.indexOf(x + "-" + y) == -1){
				visitedCells.push(x + "-" + y);
			}
			x = x * 1;
			y = y * 1;
			if(x != height - 1 && travelPuzzleState[x + 1][y] != "#" && visitedCells.indexOf((x + 1) + "-" + y) == -1){
				x++;
			}else if(x != 0 && travelPuzzleState[x - 1][y] != "#" && visitedCells.indexOf((x - 1) + "-" + y) == -1){
				x--;
			}else if(y != width - 1 && travelPuzzleState[x][y + 1] != "#" && visitedCells.indexOf(x + "-" + (y + 1)) == -1){
				y++;
			}else if(y != 0 && travelPuzzleState[x][y - 1] != "#" && visitedCells.indexOf(x + "-" + (y - 1)) == -1 ){
				y--;
			}else{
				var index = visitedCells.indexOf(x + "-" + y);
				if (index != 0){
					var lastCell = visitedCells[index - 1].split("-");
					x = lastCell[0];
					y = lastCell[1];

				}else{
					continueTraveling = false;
				}
			}
		}
	}else{
		while(continueTraveling == true){
			if (visitedCells.indexOf(x + "-" + y) == -1){
				visitedCells.push(x + "-" + y);
			}
			x = x * 1;
			y = y * 1;
			if(x != height - 1 && multiNumbers.indexOf(travelPuzzleState[x + 1][y]) != -1 && visitedCells.indexOf((x + 1) + "-" + y) == -1){
				x++;
			}else if(x != 0 && multiNumbers.indexOf(travelPuzzleState[x - 1][y]) != -1 && visitedCells.indexOf((x - 1) + "-" + y) == -1){
				x--;
			}else if(y != width - 1 && multiNumbers.indexOf(travelPuzzleState[x][y + 1]) != -1 && visitedCells.indexOf(x + "-" + (y + 1)) == -1){
				y++;
			}else if(y != 0 && multiNumbers.indexOf(travelPuzzleState[x][y - 1]) != -1 && visitedCells.indexOf(x + "-" + (y - 1)) == -1 ){
				y--;
			}else{
				var index = visitedCells.indexOf(x + "-" + y);
				if (index != 0){
					var lastCell = visitedCells[index - 1].split("-");
					x = lastCell[0];
					y = lastCell[1];

				}else{
					continueTraveling = false;
				}
			}
		}
	}
	return visitedCells;
}
function solveLogic(w, h, puzzleState, groupsArray, currSolveCount, difficulty, guessDepth, guessLimit, doingGuess){
	width = w;
	height = h;
	//puzzleState = puzzleState;
	//groupsArray = groupsArray;
	currSolveCount++;

	var oldPuzzleState = new Array(height);
	for(var i=0;i<=(height) - 1;i++){
		oldPuzzleState[i] = new Array(width);
	}
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			oldPuzzleState[x][y] = puzzleState[x][y];
		}
	}
	var oldGroupsArrayString = JSON.stringify(groupsArray);

	//checks for solved
	var isSolved = true;
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			if (puzzleState[x][y] == ("-")){
				isSolved = false;
			}
		}
	}
	if(doingGuess == true){
		isSolved = false;
	}
	//finds all empty sections
	var visitedEmptyCells = new Array();
	var visitedEmptyGroups = new Array();
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			if(puzzleState[x][y] == "-" && visitedEmptyCells.indexOf(x + "-" + y) == -1){
				var visitedCells = travelCells(width, height, x, y, puzzleState, "-");
				visitedEmptyCells.push.apply(visitedEmptyCells, visitedCells);
				visitedEmptyGroups.push(visitedCells);
			}
		}
	}
	//deletes merged wall groups
	for(h = wallGroupsArray.length - 1; h > -1; h--) {
		var currentGroup = wallGroupsArray[h];
		if(currentGroup.isMerged == true){
			wallGroupsArray.splice(h, 1);
		}
	}
	//deletes merged unnumbered groups
	for(h = groupsArray.length - 1; h > -1; h--) {
		var currentGroup = groupsArray[h];
		if(currentGroup.isMerged == true){
			groupsArray.splice(h, 1);
		}
	}
	
	//console.log(visitedEmptyGroups);
	//fills in surrounded empty groups
	for (h = 0; h < visitedEmptyGroups.length; h++) {
		var currentGroup = visitedEmptyGroups[h];
		puzzleState = fillEmptyGroup(currentGroup, puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess);
	}
	//wall drawing around finished group
	for (h = 0; h < groupsArray.length; h++) {
		var currentGroup = groupsArray[h];
		if(currentGroup.isFinished == true && currentGroup.isMerged == false){
			puzzleState = drawWallsOnFinishedGroup(currentGroup, puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess);
		}
	}

	//wall drawing where two groups almost connect
	for (h = 0; h < groupsArray.length; h++) {
		var currentGroup = groupsArray[h];
		if(currentGroup.isFinished == false && currentGroup.isMerged == false){
			puzzleState = drawWallsOnSharedEscape(currentGroup, puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess);
		}
	}
	var visitedEmptyCells = new Array();
	var visitedEmptyGroups = new Array();
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			if(puzzleState[x][y] == "-" && visitedEmptyCells.indexOf(x + "-" + y) == -1){
				var visitedCells = travelCells(width, height, x, y, puzzleState, "-");
				visitedEmptyCells.push.apply(visitedEmptyCells, visitedCells);
				visitedEmptyGroups.push(visitedCells);
			}
		}
	}
	//finds unfinished groups with one escape
	for (h = 0; h < groupsArray.length; h++) {
		var currentGroup = groupsArray[h];
		if(currentGroup.isFinished == false && currentGroup.isMerged == false){
			puzzleState = oneEscape(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess);
		}
	}

	//removes invalid escapes from wall groups
	for (h = 0; h < wallGroupsArray.length; h++) {
		var currentGroup = wallGroupsArray[h];
		if(currentGroup.isFinished == false && currentGroup.isMerged == false){
			puzzleState = removeInvalidEscapes(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess);
		}
	}

	//finds unfinished wall groups with one escape
	for (h = 0; h < wallGroupsArray.length; h++) {
		var currentGroup = wallGroupsArray[h];
		if(currentGroup.isFinished == false && currentGroup.isMerged == false){
			puzzleState = oneWallEscape(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess);
		}
	}
	//prevents 2x2 blocks of walls
	for (h = 0; h < wallGroupsArray.length; h++) {
		var currentGroup = wallGroupsArray[h];
		if(currentGroup.isFinished == false && currentGroup.isMerged == false){
			puzzleState = preventBlocks(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess);
		}
	}

	//prevents dot placement near groups with only two diagonally adjacent escapes
	for (h = 0; h < groupsArray.length; h++) {
		var currentGroup = groupsArray[h];
		if(currentGroup.isFinished == false && currentGroup.isMerged == false){
			puzzleState = twoEscapeGroups(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess);
		}
	}
	/*
	var visitedSemiEmptyCells = new Array();
	var visitedSemiEmptyGroups = new Array();
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			if((puzzleState[x][y] != "#") && visitedSemiEmptyCells.indexOf(x + "-" + y) == -1){
				var visitedCells = travelCells(width, height, x, y, puzzleState, "notwalls");
				visitedSemiEmptyCells.push.apply(visitedSemiEmptyCells, visitedCells);
				visitedSemiEmptyGroups.push(visitedCells);
			}
		}
	}*/
	for (h = 0; h < groupsArray.length; h++) {
		var currentGroup = groupsArray[h];
		if(currentGroup.isFinished == false && currentGroup.isMerged == false){
			puzzleState = drawWallsOnSharedEscape(currentGroup, puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess);
		}
	}
	//radiates from each number to find unreachable cells
	puzzleState = radiate(puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess);

	//checks wall escapes for ones that are required to connect to rest of walls
	puzzleState = replaceWallEscapes(puzzleState, width, height, visitedEmptyCells, doingGuess);

	//does the same for empty groups
	puzzleState = replaceEmptyEscapes(puzzleState, width, height, visitedEmptyCells, doingGuess);
	
	//prevents blocks near empty cells with three adjacent walls
	puzzleState = preventFillBlocks(puzzleState, width, height, visitedEmptyCells, doingGuess);

	//checks for no escapes
	if(difficulty != "easy" && difficulty != "medium"){
		for (h = 0; h < groupsArray.length; h++) {
			var currentGroup = groupsArray[h];
			if(currentGroup.getSize() * 1 != "*" && currentGroup.size * 1 > currentGroup.cells.length && currentGroup.isFinished == false && currentGroup.isMerged == false && currentGroup.escapes.length == 0){
				//console.log(groupsArray);
				//console.log("ALERT no escapes");
				//console.log(currentGroup);
				invalidGuess = true;
			}
		}
	}
	//group too large
	if(difficulty != "easy" && difficulty != "medium"){
		for (h = 0; h < groupsArray.length; h++) {
			var currentGroup = groupsArray[h];
			if(currentGroup.isMerged == false && currentGroup.size != "*" && currentGroup.cells.length > currentGroup.size * 1){
				
				//console.log("ALERT too big");
				//console.log(groupsArray);
				//console.log(currentGroup);
				//console.log(puzzleState);
				invalidGuess = true;
			}
		}
	}
	//wall group no escapes
	for(h = wallGroupsArray.length - 1; h > -1; h--) {
		var currentGroup = wallGroupsArray[h];
		if(currentGroup.isMerged == true){
			wallGroupsArray.splice(h, 1);
		}
	}
	if(difficulty != "easy" && difficulty != "medium"){
		for (h = 0; h < wallGroupsArray.length; h++) {
			var currentWallGroup = wallGroupsArray[h];
			if(currentWallGroup.isMerged == false && currentWallGroup.escapes.length == 0 && wallGroupsArray.length > 2){
				
				//console.log("ALERT no wall escapes");
				//console.log(wallGroupsArray);
				//console.log(currentGroup);
				//console.log(puzzleState);
				invalidGuess = true;
			}
		}
	}

	//console.log(groupsArray);
	//console.log(wallGroupsArray);
	//console.log(candidatesState);
	//console.log(visitedEmptyGroups);

	/*
	//finds small empty groups surrounded by all but one or all finished groups

	if(difficulty != "easy"){
		for (h = 0; h < visitedEmptyGroups.length; h++) {
			var currentEmptyGroup = visitedEmptyGroups[h];
			puzzleState = smallEmptyGroup(currentEmptyGroup, puzzleState, width, height, visitedEmptyCells, doingGuess);
		}
	}
	
	if(difficulty != "easy"){
		//finds unfinished groups that completely fill empty group
		for (h = 0; h < groupsArray.length; h++) {
			var currentGroup = groupsArray[h];
			if(currentGroup.isFinished == false && currentGroup.isMerged == false){
				puzzleState = fillEmptyGroup(currentGroup, puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess);
			}
		}
	}
	//finds unfinished groups where adjacent empty group is too small
	if(difficulty != "easy"){
		for (h = 0; h < groupsArray.length; h++) {
			var currentGroup = groupsArray[h];
			if(currentGroup.isFinished == false && currentGroup.isMerged == false){
				puzzleState = tooSmallEmptyGroup(currentGroup, puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess);
			}
		}
	}
	if(difficulty != "easy"){
		//replaces escapes with "1" to see if filling remainder is too small
		for (h = 0; h < groupsArray.length; h++) {
			var currentGroup = groupsArray[h];
			if(currentGroup.isFinished == false && currentGroup.isMerged == false){
				puzzleState = replaceEscapes(currentGroup, puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess);
			}
		}
	}
	//removes shared escapes where merge would result in an overlarge group
	if(difficulty != "easy"){
		for (h = 0; h < groupsArray.length; h++) {
			var currentGroup = groupsArray[h];
			if(currentGroup.isFinished == false && currentGroup.isMerged == false){
				puzzleState = sharedEscape(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess);
			}
		}
	}
	if(difficulty != "easy"){
		//checks escapes to see if they touch finished group of same number
		for (h = 0; h < groupsArray.length; h++) {
			var currentGroup = groupsArray[h];
			if(currentGroup.isFinished == false && currentGroup.isMerged == false){
				puzzleState = escapeFinished(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess);
			}
		}
	}



	//checks for too large groups
	if(difficulty != "easy" && difficulty != "medium"){
		for (h = 0; h < groupsArray.length; h++) {
			var currentGroup = groupsArray[h];
			if(currentGroup.getCells().length > currentGroup.getSize()){
				//console.log(groupsArray);
				//console.log("ALERT");
				//console.log(currentGroup);
				invalidGuess = true;
			}
		}
	}
	*/
	//console.log(currSolveCount);
	//console.log(puzzleState);
	//console.log(wallGroupsArray);


	var groupsArrayString = JSON.stringify(groupsArray);
	if(isSolved == false){
		if (doingGuess == false){
			if (((JSON.stringify(puzzleState) != JSON.stringify(oldPuzzleState)) || (groupsArrayString != oldGroupsArrayString))  && currSolveCount < 14) {
				solveLogic(width, height, puzzleState, groupsArray, currSolveCount, difficulty, guessDepth, guessLimit, doingGuess);
			}else{
				if(guessCount < guessLimit){
					guessCount++;
					var guessPuzzleState = JSON.parse(JSON.stringify(puzzleState));
					var escapesToRemove = new Array();
					var escapesToRemove = startGuess(width, height, guessPuzzleState, visitedEmptyCells, currSolveCount, guessDepth, guessLimit);
					console.log(escapesToRemove);

					for (var i3 = 0; i3 < escapesToRemove.length; i3++) {
						var temp = escapesToRemove[i3].split("-");
						var removeX = temp[0] * 1;
						var removeY = temp[1] * 1;
						puzzleState = addWall(puzzleState, width, height, removeX, removeY, visitedEmptyCells, doingGuess);
						/*
						for (var j3 = 0; j3 < groupsArray.length; j3++) {
							var currentGroup = groupsArray[j3];
							
							var tempEscapes = currentGroup.getEscapes();
							var index = tempEscapes.indexOf(removeX + "-" + removeY);
							if(index != -1){
								console.log("placing wall " + removeX + "-" + removeY);

								//tempEscapes.splice(index, 1);
								puzzleState = addWall(puzzleState, width, height, removeX, removeY, visitedEmptyCells, doingGuess);
							}
							
						}*/
					}
					solveCount++;
					solveLogic(width, height, puzzleState, groupsArray, currSolveCount, difficulty, guessDepth, guessLimit, doingGuess);
				}
			}
		}else{
			
			if ((JSON.stringify(puzzleState) != JSON.stringify(oldPuzzleState) || (groupsArrayString != oldGroupsArrayString)) && currSolveCount < 10000 && invalidGuess == false && guessSolveCount < guessDepth) {

				guessSolveCount++;
				solveLogic(width, height, puzzleState, groupsArray, currSolveCount, difficulty, guessDepth, guessLimit, doingGuess);
			}else{

			}
		}
	}else{
		solveCount = currSolveCount;
	}
}
function startGuess(width, height, guessPuzzleState, visitedEmptyCells, currSolveCount, guessDepth, guessLimit){
	console.log("starting guess");
	//console.log(guessPuzzleState);
	//console.log(groupsArray);
	var escapesToRemove = new Array();
	//guessCount++;
	
	//holds puzzle state for resetting later
	var startPuzzleState = JSON.parse(JSON.stringify(guessPuzzleState));
	var oldVisitedCells = JSON.parse(JSON.stringify(visitedEmptyCells));
	//var guessPuzzleState = JSON.parse(JSON.stringify(puzzleState));

	var startGroupsArray = new Array();
	for(var i = 0; i < groupsArray.length; i++){
		
		var si = groupsArray[i].getSize() + "";
		var ce = groupsArray[i].getCells().slice(0);
		var es = groupsArray[i].getEscapes().slice(0);
		var fi = groupsArray[i].getIsFinished();
		var me = groupsArray[i].getIsMerged();
		var id = groupsArray[i].getId();
		
		//startSeriesArray.push(seriesArray[x].createClone());
		var newGroup = new groupObject(si, ce, es, fi, me, id);
		startGroupsArray.push(newGroup);
	}
	var startWallGroupsArray = new Array();
	for(var i = 0; i < wallGroupsArray.length; i++){
		
		var si = wallGroupsArray[i].getSize() + "";
		var ce = wallGroupsArray[i].getCells().slice(0);
		var es = wallGroupsArray[i].getEscapes().slice(0);
		var fi = wallGroupsArray[i].getIsFinished();
		var me = wallGroupsArray[i].getIsMerged();
		var id = wallGroupsArray[i].getId();
		
		//startSeriesArray.push(seriesArray[x].createClone());
		var newGroup = new groupObject(si, ce, es, fi, me, id);
		startWallGroupsArray.push(newGroup);
	}
	var totalEscapes = new Array();
	for(i2 = startGroupsArray.length - 1; i2 > -1; i2--) {
		var guessGroupEscapes = startGroupsArray[i2].getEscapes().slice(0);
		for(var j2 = guessGroupEscapes.length - 1; j2 > -1; j2--) {
			if(totalEscapes.indexOf(guessGroupEscapes[j2]) == -1){
				totalEscapes.push(guessGroupEscapes[j2]);
			}
		}
	}
	for (i2 = 0; i2 < totalEscapes.length; i2++) {

		var coords = totalEscapes[i2].split("-");
		var guessX = coords[0] * 1;
		var guessY = coords[1] * 1;
		if(guessPuzzleState[guessX][guessY] != "#"){
			//var currentGroupSize = currentGuessGroup.getSize();
			doingGuess = true;
			//console.log(groupsArray);
			
			guessPuzzleState = modifyCell(guessPuzzleState, guessX, guessY, "none", visitedEmptyCells, doingGuess);
			//console.log(guessPuzzleState);
			//console.log(wallGroupsArray);
			solveLogic(width, height, guessPuzzleState, groupsArray, currSolveCount, difficulty, guessDepth, guessLimit, doingGuess);
			guessSolveCount = 0;
			//guessPuzzleState[guessX][guessY] = "-";
			doingGuess = false;
			
			//console.log(JSON.stringify(guessPuzzleState));
			guessPuzzleState = JSON.parse(JSON.stringify(startPuzzleState));
			//console.log(JSON.stringify(guessPuzzleState));
			
			visitedEmptyCells = JSON.parse(JSON.stringify(oldVisitedCells));
			groupsArray.length = 0;
			for(var x3 = 0; x3 < startGroupsArray.length; x3++){
				var si = startGroupsArray[x3].getSize() + "";
				var ce = startGroupsArray[x3].getCells().slice(0);
				var es = startGroupsArray[x3].getEscapes().slice(0);
				var fi = startGroupsArray[x3].getIsFinished();
				var me = startGroupsArray[x3].getIsMerged();
				var id = startGroupsArray[x3].getId();
				
				//startSeriesArray.push(seriesArray[x].createClone());
				var newGroup = new groupObject(si, ce, es, fi, me, id);
				groupsArray.push(newGroup);
			}
			wallGroupsArray.length = 0;
			for(var x3 = 0; x3 < startWallGroupsArray.length; x3++){
				var si = startWallGroupsArray[x3].getSize() + "";
				var ce = startWallGroupsArray[x3].getCells().slice(0);
				var es = startWallGroupsArray[x3].getEscapes().slice(0);
				var fi = startWallGroupsArray[x3].getIsFinished();
				var me = startWallGroupsArray[x3].getIsMerged();
				var id = startWallGroupsArray[x3].getId();
				
				//startSeriesArray.push(seriesArray[x].createClone());
				var newGroup = new groupObject(si, ce, es, fi, me, id);
				wallGroupsArray.push(newGroup);
			}

			//remove escapes that cause invalid positions
			//console.log("guessing at " + guessX + "-" + guessY);
			if (invalidGuess == true){
				console.log("invalid guess at " + guessX + "-" + guessY);
				escapesToRemove.push(guessX + "-" + guessY);
				//console.log(groupsArray);
			}
			invalidGuess = false;
		}
	}

	//console.log(guessPuzzleState);
	//console.log(groupsArray);
	//console.log("WHAT");
	return escapesToRemove;
	
}
function preventFillBlocks(puzzleState, width, height, visitedEmptyCells, doingGuess){
	//console.log("preventing fill blocks");
	for (var x3 = 0;x3 < height;x3++) {
		for (var y3 = 0; y3 < width;y3++) {
			
			var wallCount = 0;
			var emptyX = "";
			var emptyY = "";
			if(puzzleState[x3][y3] == "-"){
				if(x3 == 0 || puzzleState[x3 - 1][y3] == "#"){
					wallCount++;
					
				}else{
					if(x3 != 0 && puzzleState[x3 - 1][y3] == "-"){
						emptyX = x3 - 1;
						emptyY = y3;
					}
				}
				if(x3 == height - 1 || puzzleState[x3 + 1][y3] == "#"){
					wallCount++;
					
				}else{
					if(x3 != height - 1 && puzzleState[x3 + 1][y3] == "-"){
						emptyX = x3 + 1;
						emptyY = y3;
					}
				}
				if(y3 == 0 || puzzleState[x3][y3 - 1] == "#"){
					wallCount++;
					
				}else{
					if(y3 != 0 && puzzleState[x3][y3 - 1] == "-"){
						emptyX = x3;
						emptyY = y3 - 1;
					}
				}
				if(y3 == width - 1 || puzzleState[x3][y3 + 1] == "#"){
					wallCount++;
					
				}else{
					if(x3 != width - 1 && puzzleState[x3][y3 + 1] == "-"){
						emptyX = x3;
						emptyY = y3 + 1;
					}
				}
				if(wallCount == 3 && emptyX != ""){
					
					//console.log(emptyX + "-" + emptyY);
					if(x3 != emptyX){
						if(y3 != 0 && puzzleState[emptyX][emptyY - 1] == "#"){
							//console.log("found " + emptyX + "-" + emptyY);
							//console.log(puzzleState[x3 - 1]);
							//console.log(puzzleState[x3]);
							//console.log(puzzleState[x3 + 1]);
							puzzleState = modifyCell(puzzleState, emptyX, emptyY, "none", visitedEmptyCells, doingGuess);
						}else if(y3 != width - 1 && puzzleState[emptyX][emptyY + 1] == "#"){
							//console.log("found " + emptyX + "-" + emptyY);
							puzzleState = modifyCell(puzzleState, emptyX, emptyY, "none", visitedEmptyCells, doingGuess);
						}
					}else if(y3 != emptyY){
						if(x3 != 0 && puzzleState[emptyX - 1][emptyY] == "#"){
							//console.log("found " + emptyX + "-" + emptyY);
							puzzleState = modifyCell(puzzleState, emptyX, emptyY, "none", visitedEmptyCells, doingGuess);
						}else if(x3 != height - 1 && puzzleState[emptyX + 1][emptyY] == "#"){
							//console.log("found " + emptyX + "-" + emptyY);
							puzzleState = modifyCell(puzzleState, emptyX, emptyY, "none", visitedEmptyCells, doingGuess);
						}
					}
				}
			}
		}
	}
	return puzzleState;
}
function twoEscapeGroups(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess){
	
	if(currentGroup.escapes.length == 2){
		//console.log(currentGroup);
		var temp = currentGroup.escapes[0].split("-");
		var x1 = temp[0] * 1;
		var y1 = temp[1] * 1;
		temp = currentGroup.escapes[1].split("-");
		var x2 = temp[0] * 1;
		var y2 = temp[1] * 1;
		var diagonallyAdjacent = false;
		if(Math.abs(x1 - x2) == 1 && Math.abs(y1 - y2) == 1 ){
			//console.log("FOUND " + x1 + "-" + y1 + " " + x2 + "-" + y2);
			var addX;
			var addY;
			if(currentGroup.cells.indexOf(x1 + "-" + y2) == -1){
				addX = x1;
				addY = y2;
			}if(currentGroup.cells.indexOf(x2 + "-" + y1) == -1){
				addX = x2;
				addY = y1;
			}
			
			if(currentGroup.size == 2 || (currentGroup.size - currentGroup.cells.length + 1) == 2){
				//console.log("adding wall at " + addX + "-" + addY);
				puzzleState = addWall(puzzleState, width, height, addX, addY, visitedEmptyCells, doingGuess);
			}else{
				
				for (k = 0; k < groupsArray.length; k++) {
					//console.log(currentGroup.id);
					//console.log(groupsArray[k].id);
					if(groupsArray[k].isFinished == false && groupsArray[k].isMerged == false && groupsArray[k].id != currentGroup.id && groupsArray[k].size != "*"){
						var index = groupsArray[k].escapes.indexOf(addX + "-" + addY);
						if(index != -1){

							//console.log("adding wall at " + addX + "-" + addY);
							//console.log(groupsArray[k]);
							//console.log(currentGroup);
							if(currentGroup.size == "*"){
								if(groupsArray[k].size < currentGroup.cells.length + 2 + groupsArray[k].cells.length){
									puzzleState = addWall(puzzleState, width, height, addX, addY, visitedEmptyCells, doingGuess);
								}
							}else{
							
								puzzleState = addWall(puzzleState, width, height, addX, addY, visitedEmptyCells, doingGuess);
							}
							//groupsArray[k].escapes.splice(index, 1);
						}
					}
				}
			}
		}
	}
	return puzzleState;
}

function radiate(puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess){
	//console.log(visitedEmptyGroups);
	var reachedCells = new Array();
	var numberIsFinished = false;
	var groupLayersArray = new Array();
	for (i = 0; i < groupsArray.length; i++) {
		var currentRadiateGroup = groupsArray[i];
		if(currentRadiateGroup.isMerged == false && currentRadiateGroup.isFinished == false){
			if(currentRadiateGroup.size != "*"){
				var startCell;
				for (j = 0; j < currentRadiateGroup.cells.length; j++) {
					var temp = currentRadiateGroup.cells[j].split("-");
					var startX = temp[0] * 1;
					var startY = temp[1] * 1;
					if(puzzleState[startX][startY] != "*"){
						startCell = currentRadiateGroup.cells[j];
					}
				}	
				var length = (currentRadiateGroup.size * 1) - currentRadiateGroup.cells.length;
				var temp = smartRadiate(puzzleState, width, height, length, currentRadiateGroup, doingGuess);
				accessibleCells = temp[0];
				var layers = temp[1];
				//console.log(accessibleCells);
				reachedCells.push.apply(reachedCells, accessibleCells);
				//console.log(layers.flat(length));

				//fills groups where accessible cells equal group size
				var layerCells = layers.reduce((acc, val) => acc.concat(val), []);
				//console.log(layerCells.length);
				if(layerCells.length == currentRadiateGroup.size){
					for (m = 0; m < layerCells.length; m++) {
						var temp = layerCells[m].split("-");
						var newX = temp[0] * 1;
						var newY = temp[1] * 1;
						if(puzzleState[newX][newY] == "-"){
							puzzleState = modifyCell(puzzleState, newX, newY, currentRadiateGroup, visitedEmptyCells, doingGuess);
						}
					}
				}
				
				var radiateEscapes = currentRadiateGroup.escapes;
				//console.log(radiateEscapes);
				var neededCells = new Array();
				var escapeLayers = new Array();
				for (n = 0; n < radiateEscapes.length; n++) {
					var validEscape = true;
					for (p = 0; p < groupsArray.length; p++) {
						if(groupsArray[p].id != groupsArray[i].id && groupsArray[p].size != "*"){
							if(groupsArray[p].escapes.indexOf(radiateEscapes[n]) != -1){
								validEscape = false;
							}
						}
					}
					if(validEscape == true){
						var temp = radiateEscapes[n].split("-");
						var newX = temp[0] * 1;
						var newY = temp[1] * 1;
						var oldRadiateState = puzzleState[newX][newY] + "";
						//puzzleState[newX][newY] = "#";
						//puzzleState[newX][newY] = oldRadiateState;
						if(puzzleState[newX][newY] == "-"){
							//console.log(newX + "-" + newY);
							puzzleState[newX][newY] = "#";

							var temp = smartRadiate(puzzleState, width, height, length, currentRadiateGroup, doingGuess);
							puzzleState[newX][newY] = oldRadiateState + "";
							var radiateLayers = temp[1];
							var radiateLayerCells = radiateLayers.reduce((acc, val) => acc.concat(val), []);
							escapeLayers.push.apply(escapeLayers, radiateLayerCells);
							if(radiateLayerCells.length < currentRadiateGroup.size){
								//console.log("found " + newX + "-" + newY);
								//console.log(radiateEscapes);
								neededCells.push(newX + "-" + newY);
								
							}
						}
					}	
				}
				escapeLayers = Array.from(new Set(escapeLayers));
				var temp = startCell.split("-");
				var startX = temp[0] * 1;
				var startY = temp[1] * 1;
				groupLayersArray.push([puzzleState[startX][startY] * 1, escapeLayers, startCell]);
				for (n = 0; n < neededCells.length; n++) {
					var temp = neededCells[n].split("-");
					var newX = temp[0] * 1;
					var newY = temp[1] * 1;
					puzzleState = modifyCell(puzzleState, newX, newY, currentRadiateGroup, visitedEmptyCells, doingGuess);
				}
			}else{

			}
		}
	}
	//console.log(groupLayersArray);
	/*
	for (var x=0;x < (height);x++) {
		for (var y=0; y < (width);y++) {
			numberIsFinished = false;
			if(Number.isInteger(puzzleState[x][y] * 1)){

				var currentNumberGroup = "none";
				for (i = 0; i < groupsArray.length; i++) {
					if(groupsArray[i].cells.indexOf(x + "-" + y) != -1){
						currentNumberGroup = groupsArray[i];
						if(groupsArray[i].isFinished == true){
							numberIsFinished = true;
						}
					}
				}
				//console.log(groupsArray);
				//console.log(currentNumberGroup);
				if(numberIsFinished == false && currentNumberGroup != "none"){
					
					//console.log(x + "-" + y);
					var length = puzzleState[x][y] * 1 - currentNumberGroup.cells.length;
					var temp = smartRadiate(puzzleState, width, height, length, currentNumberGroup, visitedEmptyCells, visitedEmptyGroups, doingGuess);
					accessibleCells = temp[0];
					var layers = temp[1];
					//console.log(accessibleCells);
					reachedCells.push.apply(reachedCells, accessibleCells);
					//console.log(layers.flat(length));

					//fills groups where accessible cells equal group size
					var layerCells = layers.reduce((acc, val) => acc.concat(val), []);
					//console.log(layerCells.length);
					if(layerCells.length == currentNumberGroup.size){
						for (j = 0; j < layerCells.length; j++) {
							var temp = layerCells[j].split("-");
							var newX = temp[0] * 1;
							var newY = temp[1] * 1;
							if(puzzleState[newX][newY] == "-"){
								puzzleState = modifyCell(puzzleState, newX, newY, currentNumberGroup, visitedEmptyCells, doingGuess);
							}
						}
					}
				}
			}
		}
	}*/
	//console.log(reachedCells);
	for (var x3=0;x3 < (height);x3++) {
		for (var y3=0; y3 < (width);y3++) {
			if(reachedCells.indexOf(x3 + "-" + y3) == -1){
				addWall(puzzleState, width, height, x3, y3, visitedEmptyCells, doingGuess);
				//console.log("unreachable " + x3 + "-" + y3);
			}
		}
	}
	//finds unnumbered groups that can only be reached by one number
	var totalReachableCells = new Array();
	for (i = 0; i < groupLayersArray.length; i++) {
		totalReachableCells.push.apply(totalReachableCells, groupLayersArray[i][1]);
	}
	//console.log(totalReachableCells);
	for (i = 0; i < groupsArray.length; i++) {
		if(groupsArray[i].size == "*" && groupsArray[i].cells.length == 1 && groupsArray[i].isMerged == false){
			var occurrenceCount = 0;
			for (j = 0; j < totalReachableCells.length; j++) {
				if(totalReachableCells[j] == groupsArray[i].cells[0]){
					occurrenceCount++;
				}
			}
			if(occurrenceCount == 1){
				//10x10:-,1,-,-,-,-,-,-,-,-,-,-,-,-,5,-,-,-,-,5,-,2,-,-,-,-,-,-,-,-,-,-,2,-,-,1,-,-,-,-,-,-,-,-,-,-,3,-,-,-,-,-,-,-,-,-,-,-,-,-,3,-,3,-,-,-,-,4,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,2,-,-,-,-,5,-,-,-,4,-,-,
				//10x10:-,-,-,4,-,-,-,-,-,-,-,-,2,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,5,-,-,-,-,-,-,-,-,1,-,-,-,-,-,-,4,-,-,-,-,-,4,-,5,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,1,-,2,-,-,-,-,-,3,-,-,1,-,4,-,5,-,-,-,-,-,-,-,
				//10x10:10,-,-,-,-,-,-,3,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,-,3,-,-,-,-,-,1,-,-,-,-,1,-,-,1,-,-,-,-,-,-,-,-,-,-,-,-,-,3,-,-,2,-,-,-,-,5,-,-,-,-,-,-,-,-,-,-,-,-,-,-,2,-,-,-,-,-,-,-,-,-,-,5,-,4,-,1,-,-,-,-,4,
				for (k = 0; k < groupLayersArray.length; k++) {
					if(groupLayersArray[k][1].indexOf(groupsArray[i].cells[0]) != -1 ){
						//console.log(groupLayersArray);
						//console.log(groupsArray);
						var temp = groupsArray[i].cells[0].split("-");
						var foundX = temp[0] * 1;
						var foundY = temp[1] * 1;
						var temp = groupLayersArray[k][2].split("-");
						var startX = temp[0] * 1;
						var startY = temp[1] * 1;
						var length = groupLayersArray[k][0] * 1;
						if(foundX == startX){
							
							if(Math.abs(foundY - startY) + 1 == length){
								//console.log("found barely reachable cell at " + groupsArray[i].cells[0] + " from " + groupLayersArray[k][2] + " length " + groupLayersArray[k][0]);
								if(foundY > startY){
									for(newY = startY + 1; newY < foundY; newY++){
										//modifyCell(puzzleState, foundX, newY, "none", visitedEmptyCells, doingGuess);
									}
								}else if(foundY < startY){
									for(newY = foundY + 1; newY < startY; newY++){
										//modifyCell(puzzleState, foundX, newY, "none", visitedEmptyCells, doingGuess);
									}
								}
							}
						}else if(foundY == startY){
							
							if(Math.abs(foundX - startX) + 1 == length){
								//console.log("found barely reachable cell at " + groupsArray[i].cells[0] + " from " + groupLayersArray[k][2] + " length " + groupLayersArray[k][0]);
								if(foundX > startX){
									for(newX = startX + 1; newX < foundX; newX++){
										//modifyCell(puzzleState, newX, foundY, "none", visitedEmptyCells, doingGuess);
									}
								}else if(foundX < startX){
									for(newX = foundX + 1; newX < startX; newX++){
										//modifyCell(puzzleState, newX, foundY, "none", visitedEmptyCells, doingGuess);
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return puzzleState;
}
function replaceWallEscapes(puzzleState, width, height, visitedEmptyCells, doingGuess){
	var wallCount = 0;
	var numberCount = 0;
	for (var x3=0;x3 < (height);x3++) {
		for (var y3=0; y3 < (width);y3++) {
			if(puzzleState[x3][y3] == "#"){
				wallCount++;
			}
			if(Number.isInteger(puzzleState[x3][y3] * 1)){
				numberCount++;
			}
		}
	}
	var maxWallCount = (width * height) - numberCount;
	for (i = 0; i < wallGroupsArray.length; i++) {
		var currentRadiateGroup = wallGroupsArray[i];
		var radiateEscapes = currentRadiateGroup.escapes;
		//console.log(radiateEscapes);
		var neededCells = new Array();
		
		for (n = 0; n < radiateEscapes.length; n++) {
			var validEscape = true;
			/*
			for (p = 0; p < wallGroupsArray.length; p++) {
				if(wallGroupsArray[p].id != wallGroupsArray[i].id){
					if(wallGroupsArray[p].escapes.indexOf(radiateEscapes[n]) != -1){
						validEscape = false;
					}
				}
			}*/
			
			if(validEscape == true){
				var temp = radiateEscapes[n].split("-");
				var newX = temp[0] * 1;
				var newY = temp[1] * 1;
				var oldRadiateState = puzzleState[newX][newY] + "";
				//puzzleState[newX][newY] = "#";
				//puzzleState[newX][newY] = oldRadiateState;
				if(puzzleState[newX][newY] == "-"){
					//console.log(newX + "-" + newY);
					puzzleState[newX][newY] = "*";
					var isValidFill = fillWalls(puzzleState, width, height, currentRadiateGroup, doingGuess, wallCount, maxWallCount);
					puzzleState[newX][newY] = oldRadiateState + "";

					if(isValidFill == false){
						//console.log("found " + newX + "-" + newY);
						//console.log(wallCount);
						//console.log(filledGroup);
						//console.log(radiateEscapes);
						neededCells.push(newX + "-" + newY);
						
					}
				}
			}
		}
		for (n = 0; n < neededCells.length; n++) {
			var temp = neededCells[n].split("-");
			var newX = temp[0] * 1;
			var newY = temp[1] * 1;
			puzzleState = addWall(puzzleState, width, height, newX, newY, visitedEmptyCells, doingGuess);
		}
	}
	return puzzleState;
}
function replaceEmptyEscapes(puzzleState, width, height, visitedEmptyCells, doingGuess){
	/*
	var wallCount = 0;
	var numberCount = 0;
	for (var x3=0;x3 < (height);x3++) {
		for (var y3=0; y3 < (width);y3++) {
			if(puzzleState[x3][y3] == "#"){
				wallCount++;
			}
			if(Number.isInteger(puzzleState[x3][y3] * 1)){
				numberCount++;
			}
		}
	}
	var maxWallCount = (width * height) - numberCount;*/
	for (i = 0; i < groupsArray.length; i++) {
		if(groupsArray[i].size == "*" && groupsArray[i].isFinished == false && groupsArray[i].isMerged == false && groupsArray[i].escapes.length > 1){
			var currentRadiateGroup = groupsArray[i];
			var radiateEscapes = currentRadiateGroup.escapes;
			//console.log(radiateEscapes);
			var neededCells = new Array();
			
			for (n = 0; n < radiateEscapes.length; n++) {
				var validEscape = true;
				/*
				for (p = 0; p < wallGroupsArray.length; p++) {
					if(wallGroupsArray[p].id != wallGroupsArray[i].id){
						if(wallGroupsArray[p].escapes.indexOf(radiateEscapes[n]) != -1){
							validEscape = false;
						}
					}
				}*/
				
				if(validEscape == true){
					var temp = radiateEscapes[n].split("-");
					var newX = temp[0] * 1;
					var newY = temp[1] * 1;
					var oldRadiateState = puzzleState[newX][newY] + "";
					//puzzleState[newX][newY] = "#";
					//puzzleState[newX][newY] = oldRadiateState;
					if(puzzleState[newX][newY] == "-"){
						//console.log(newX + "-" + newY);
						puzzleState[newX][newY] = "#";
						var isValidFill = fillDots(puzzleState, width, height, currentRadiateGroup, doingGuess);
						puzzleState[newX][newY] = oldRadiateState + "";

						if(isValidFill == false){
							//console.log("found " + newX + "-" + newY);
							//console.log(wallCount);
							//console.log(filledGroup);
							//console.log(radiateEscapes);
							neededCells.push(newX + "-" + newY);
							
						}
					}
				}
			}
			for (n = 0; n < neededCells.length; n++) {
				var temp = neededCells[n].split("-");
				var newX = temp[0] * 1;
				var newY = temp[1] * 1;
				puzzleState = modifyCell(puzzleState, newX, newY, currentRadiateGroup, visitedEmptyCells, doingGuess);
			}
		}
	}
	return puzzleState;
}
function fillDots(puzzleState, width, height, fillGroup, doingGuess){
	var invalidEscapes = new Array();
	var visitedCells = fillGroup.cells.slice(0);
	//visitedCells.push(x + "-" + y);
	//console.log(visitedCells);
	var temp = visitedCells[visitedCells.length - 1].split("-");
	var x = temp[0] * 1;
	var y = temp[1] * 1;
	var continueTraveling = true;
	var isValidFill = true;
	var foundNewGroup = false;
	while(continueTraveling == true){
		if(visitedCells.indexOf(x + "-" + y) == -1){
			visitedCells.push(x + "-" + y);
		}
		if((puzzleState[x][y] == "*" || Number.isInteger(puzzleState[x][y] * 1)) && fillGroup.cells.indexOf(x + "-" + y) == -1){
			continueTraveling = false;
			foundNewGroup = true;
		}
		x = x * 1;
		y = y * 1;
		if(x != height - 1 && (puzzleState[x + 1][y] != "#") && visitedCells.indexOf((x + 1) + "-" + y) == -1 && invalidEscapes.indexOf((x + 1) + "-" + y) == -1){
			x++;
		}else if(x != 0 && (puzzleState[x - 1][y] != "#") && visitedCells.indexOf((x - 1) + "-" + y) == -1 && invalidEscapes.indexOf((x - 1) + "-" + y) == -1){
			x--;
		}else if(y != width - 1 && (puzzleState[x][y + 1] != "#") && visitedCells.indexOf(x + "-" + (y + 1)) == -1 && invalidEscapes.indexOf(x + "-" + (y + 1)) == -1){
			y++;
		}else if(y != 0 && (puzzleState[x][y - 1] != "#") && visitedCells.indexOf(x + "-" + (y - 1)) == -1 && invalidEscapes.indexOf(x + "-" + (y - 1)) == -1){
			y--;
		}else{
			var index = visitedCells.indexOf(x + "-" + y);
			if (index != 0){
				var lastCell = visitedCells[index - 1].split("-");
				x = lastCell[0];
				y = lastCell[1];

			}else{
				continueTraveling = false;
			}
		}
	}
	if(foundNewGroup == false){
		isValidFill = false;
	}
	return isValidFill;
}
function fillWalls(puzzleState, width, height, fillGroup, doingGuess, wallCount, maxWallCount){
	var invalidEscapes = new Array();
	var visitedCells = fillGroup.cells.slice(0);
	//visitedCells.push(x + "-" + y);
	//console.log(visitedCells);
	var temp = visitedCells[visitedCells.length - 1].split("-");
	var x = temp[0] * 1;
	var y = temp[1] * 1;
	var continueTraveling = true;
	var isValidFill = true;
	var foundNewGroup = false;
	while(continueTraveling == true){
		if(visitedCells.indexOf(x + "-" + y) == -1){
			visitedCells.push(x + "-" + y);
		}
		if(puzzleState[x][y] == "#" && fillGroup.cells.indexOf(x + "-" + y) == -1){
			continueTraveling = false;
			foundNewGroup = true;
		}
		x = x * 1;
		y = y * 1;
		if(x != height - 1 && (puzzleState[x + 1][y] == "-" || puzzleState[x + 1][y] == "#") && visitedCells.indexOf((x + 1) + "-" + y) == -1 && invalidEscapes.indexOf((x + 1) + "-" + y) == -1){
			x++;
		}else if(x != 0 && (puzzleState[x - 1][y] == "-" || puzzleState[x - 1][y] == "#") && visitedCells.indexOf((x - 1) + "-" + y) == -1 && invalidEscapes.indexOf((x - 1) + "-" + y) == -1){
			x--;
		}else if(y != width - 1 && (puzzleState[x][y + 1] == "-" || puzzleState[x][y + 1] == "#") && visitedCells.indexOf(x + "-" + (y + 1)) == -1 && invalidEscapes.indexOf(x + "-" + (y + 1)) == -1){
			y++;
		}else if(y != 0 && (puzzleState[x][y - 1] == "-" || puzzleState[x][y - 1] == "#") && visitedCells.indexOf(x + "-" + (y - 1)) == -1 && invalidEscapes.indexOf(x + "-" + (y - 1)) == -1){
			y--;
		}else{
			var index = visitedCells.indexOf(x + "-" + y);
			if (index != 0){
				var lastCell = visitedCells[index - 1].split("-");
				x = lastCell[0];
				y = lastCell[1];

			}else{
				continueTraveling = false;
			}
		}
	}
	if(foundNewGroup == false && visitedCells.length < wallCount && visitedCells.length < maxWallCount){
		isValidFill = false;
	}
	return isValidFill;
}
function smartRadiate(puzzleState, width, height, length, currentRadiateGroup, doingGuess){
	//var originCell = x + "-" + y;
	var originCell;
	var visitedCells = new Array();
	var groupLayers = new Array();
	
	var newLayer = currentRadiateGroup.cells;
	visitedCells.push.apply(visitedCells, newLayer);
	//var newLayer = [x + "-" + y];
	//visitedCells.push(x + "-" + y);
	groupLayers.push(newLayer);
	var currentLayer = 0;
	
	while(currentLayer < length){
		newLayer = new Array();
		for (j = 0; j < groupLayers[currentLayer].length; j++) {
			var temp = groupLayers[currentLayer][j].split("-");
			x = temp[0] * 1;
			y = temp[1] * 1;
			if(x != height - 1 && visitedCells.indexOf((x + 1) + "-" + y) == -1){
				var isValid = isValidTravel(puzzleState, width, height, x + 1, y, currentRadiateGroup);
				if(isValid == true){
					newLayer.push((x + 1) + "-" + y);
					visitedCells.push((x + 1) + "-" + y);
				}
			}
			if(x != 0 && visitedCells.indexOf((x - 1) + "-" + y) == -1){
				var isValid = isValidTravel(puzzleState, width, height, x - 1, y, currentRadiateGroup);
					if(isValid == true){
					newLayer.push((x - 1) + "-" + y);
					visitedCells.push((x - 1) + "-" + y);
				}
			}
			if(y != width - 1 && visitedCells.indexOf(x + "-" + (y + 1)) == -1){
				var isValid = isValidTravel(puzzleState, width, height, x, y + 1, currentRadiateGroup);
					if(isValid == true){
					newLayer.push(x + "-" + (y + 1));
					visitedCells.push(x + "-" + (y + 1));
				}
			}
			if(y != 0 && visitedCells.indexOf(x + "-" + (y - 1)) == -1){
				var isValid = isValidTravel(puzzleState, width, height, x, y - 1, currentRadiateGroup);
					if(isValid == true){
					newLayer.push(x + "-" + (y - 1));
					visitedCells.push(x + "-" + (y - 1));
				}
			}
		}
		groupLayers.push(newLayer);
		currentLayer++;
	}
	//console.log(groupLayers);
	var returnArray = [visitedCells, groupLayers];
	return returnArray;
}
function isValidTravel(puzzleState, width, height, x, y, group){
	//var temp = originCell.split("-");
	//var originX = temp[0] * 1;
	//var originY = temp[1] * 1;
	var isValid = true;
	
	for (k = 0; k < groupsArray.length; k++) {
		if(groupsArray[k] != group && groupsArray[k].isMerged == false){
			if(groupsArray[k].size != "*"){
				if(groupsArray[k].cells.indexOf(x + "-" + y) != -1){
					isValid = false;
					//return isValid;
				}
				if(groupsArray[k].escapes.indexOf(x + "-" + y) != -1){
					isValid = false;
					//return isValid;
				}
			}
		}
	}
	if(puzzleState[x][y] != "-"){
		isValid = false;
		//return isValid;
	}
	if(puzzleState[x][y] == "*"){
		if(group.cells.indexOf(x + "-" + y) != -1){
			isValid = true;
			
		}else{
			isValid = false;
			for (l = 0; l < groupsArray.length; l++) {
				if(groupsArray[l].size == "*" && groupsArray[l].cells.indexOf(x + "-" + y) != -1){
					isValid = true;
				}
			}
			
			//return isValid;
		}
	}

	return isValid;
}
function fillEmptyGroup(currentEmptyGroup, puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess){
	var foundExit = false;
	for (i = 0; i < currentEmptyGroup.length; i++) {
		var temp = currentEmptyGroup[i].split("-");
		var x = temp[0] * 1;
		var y = temp[1] * 1;
		if(x != 0){
			if(puzzleState[x - 1][y] != "#" && puzzleState[x - 1][y] != "-"){
				foundExit = true;
			}
		}
		if(x != height - 1){
			if(puzzleState[x + 1][y] != "#" && puzzleState[x + 1][y] != "-"){
				foundExit = true;
			}
		}
		if(y != 0){
			if(puzzleState[x][y - 1] != "#" && puzzleState[x][y - 1] != "-"){
				foundExit = true;
			}
		}
		if(y != width - 1){
			if(puzzleState[x][y + 1] != "#" && puzzleState[x][y + 1] != "-"){
				foundExit = true;
			}
		}

	}
	//console.log(currentEmptyGroup);
	//console.log(foundExit);
	if(foundExit == false){
		//console.log("FUCK");
		for (i = 0; i < currentEmptyGroup.length; i++) {
			var temp = currentEmptyGroup[i].split("-");
			var x = temp[0] * 1;
			var y = temp[1] * 1;
			addWall(puzzleState, width, height, x, y, visitedEmptyCells, doingGuess);
		}
	}
	return puzzleState;
}
function drawWallsOnFinishedGroup(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess){
	var currentCells = currentGroup.getCells();
	for (i = 0; i < currentCells.length; i++) {
		var temp = currentCells[i].split("-");
		var x = temp[0] * 1;
		var y = temp[1] * 1;
		if(x != 0 && currentCells.indexOf((x - 1) + "-" + y) == -1){
			addWall(puzzleState, width, height, x - 1, y, visitedEmptyCells, doingGuess);
		}
		if(x != height - 1 && currentCells.indexOf((x + 1) + "-" + y) == -1){
			addWall(puzzleState, width, height, x + 1, y, visitedEmptyCells, doingGuess);
		}
		if(y != 0 && currentCells.indexOf(x + "-" + (y - 1)) == -1){
			addWall(puzzleState, width, height, x, y - 1, visitedEmptyCells, doingGuess);
		}
		if(y != width - 1 && currentCells.indexOf(x + "-" + (y + 1)) == -1){
			addWall(puzzleState, width, height, x, y + 1, visitedEmptyCells, doingGuess);
		}
	}
	return puzzleState;
}
function drawWallsOnSharedEscape(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess){

	var groupEscapes = currentGroup.escapes;
	var escapeGroups = new Array();
	
	if(currentGroup.size != "*"){
		
		for(i = groupEscapes.length - 1; i > -1; i--) {
			var adjacentGroups = new Array();
			var foundOtherNumber = false;
			for (j = 0; j < groupsArray.length; j++) {
				var checkGroup = groupsArray[j];
				var checkEscapes = checkGroup.escapes;
				if(checkGroup.id != currentGroup.id){
					if(checkGroup.escapes.indexOf(groupEscapes[i]) != -1 && checkGroup.isMerged == false && currentGroup.isMerged == false){
						adjacentGroups.push(checkGroup);
						if(checkGroup.size != "*"){
							foundOtherNumber = true;
							escapeGroups.push(checkGroup);
						}
					}
				}
			}
			//console.log(escapeGroups);
			//console.log(adjacentGroups);
			if(foundOtherNumber == false){
				var totalCellCount = currentGroup.cells.length * 1;
				for (j = 0; j < adjacentGroups.length; j++) {
					var adjacentCells = adjacentGroups[j].cells;
					totalCellCount += adjacentCells.length;
				}
				if((totalCellCount * 1) + 1 > currentGroup.size){
					for (j = 0; j < adjacentGroups.length; j++) {
						escapeGroups.push(adjacentGroups[j]);
					}
				}
			}
			//console.log(escapeGroups);
			for (m = 0; m < escapeGroups.length; m++){
				if(escapeGroups.length == 1){
					var checkEscapes = escapeGroups[m].escapes;
					var index = checkEscapes.indexOf(groupEscapes[i]);
					if(index != -1){
						var temp = checkEscapes[index].split("-");
						var addX = temp[0] * 1;
						var addY = temp[1] * 1;
						puzzleState = addWall(puzzleState, width, height, addX, addY, visitedEmptyCells, doingGuess);
					}
					
				}else{
					var escapeInAllGroups = true;
					for (j = 0; j < escapeGroups.length; j++) {
						var index = escapeGroups[j].escapes.indexOf(groupEscapes[i]);
						if(index == -1){
							escapeInAllGroups = false
						}
					}
					if(escapeInAllGroups == true){
						var temp = groupEscapes[i].split("-");
						var addX = temp[0] * 1;
						var addY = temp[1] * 1;
						puzzleState = addWall(puzzleState, width, height, addX, addY, visitedEmptyCells, doingGuess);
					}
				}
			}
		}
	}
	/*
	for(i = groupEscapes.length - 1; i > -1; i--) {
		var escapeGroups = new Array();
		for (j = 0; j < groupsArray.length; j++) {
			var checkGroup = groupsArray[j];
			var checkEscapes = checkGroup.escapes;
			if(checkGroup.id != currentGroup.id && checkGroup.size != "*" && currentGroup.size != "*"){
				
				var index = checkEscapes.indexOf(groupEscapes[i]);
				if(index != -1 && checkGroup.isMerged == false && currentGroup.isMerged == false){
					//console.log(groupEscapes[i]);
					escapeGroups.push(checkGroup);

				}
			}
			
			if(checkGroup.id != currentGroup.id){
				if(checkGroup.size == "*" || currentGroup.size == "*"){
					if(!(checkGroup.size == "*" && currentGroup.size == "*")){
						var index = checkEscapes.indexOf(groupEscapes[i]);
						if(index != -1 && checkGroup.isMerged == false && currentGroup.isMerged == false){
							
							var size;
							if(checkGroup.size == "*"){
								size = currentGroup.size * 1;
							}else{
								size = checkGroup.size * 1;
							}
							//console.log(checkGroup.cells.length + " " + currentGroup.cells.length + " " + size);
							//console.log(checkGroup.cells);
							//console.log(currentGroup.cells);
							if((checkGroup.cells.length * 1) + (currentGroup.cells.length * 1) + 1 > size * 1){
								//console.log("WAAAH");
								//console.log(groupEscapes[i]);
								escapeGroups.push(checkGroup);
							}

						}
					}
				}
			}
		}		
		for (k = 0; k < escapeGroups.length; k++){
			var checkEscapes = escapeGroups[k].escapes;
			var index = checkEscapes.indexOf(groupEscapes[i]);
			if(index != -1){
				var temp = checkEscapes[index].split("-");
				var addX = temp[0] * 1;
				var addY = temp[1] * 1;
				puzzleState = addWall(puzzleState, width, height, addX, addY, visitedEmptyCells, doingGuess);
			}
		}		
	}*/
	return puzzleState;
}
function oneEscape(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess){
	var escapes = currentGroup.escapes;
	//console.log(currentGroup.size + "-" + allEscapes.length);
	if(escapes.length == 1){
		var coords = escapes[0].split("-");
		var escapex = coords[0] * 1;
		var escapey = coords[1] * 1;

		//console.log(allEscapes[0]);

		puzzleState = modifyCell(puzzleState, escapex, escapey, currentGroup, visitedEmptyCells, doingGuess);
	}
	
	return puzzleState;
}
function oneWallEscape(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess){
	var escapes = currentGroup.escapes;
	//console.log(currentGroup.size + "-" + allEscapes.length);
	if(escapes.length == 1){
		var coords = escapes[0].split("-");
		var escapeX = coords[0] * 1;
		var escapeY = coords[1] * 1;

		//console.log(allEscapes[0]);

		puzzleState = addWall(puzzleState, width, height, escapeX, escapeY, visitedEmptyCells, doingGuess);
	}
	
	return puzzleState;
}
function removeInvalidEscapes(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess){
	var escapes = currentGroup.escapes;
	//console.log(currentGroup.size + "-" + allEscapes.length);
	for(i = escapes.length - 1; i > -1; i--) {
		var temp = escapes[i].split("-");
		var escapeX = temp[0] * 1;
		var escapeY = temp[1] * 1;
		if(puzzleState[escapeX][escapeY] != "-"){
			escapes.splice(i, 1);
		}
	}
	
	return puzzleState;
}
function preventBlocks(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess){
	var cells = currentGroup.getCells();
	if(cells.length > 2){
		for (i = 0; i < cells.length; i++) {
			var temp = cells[i].split("-");
			var x = temp[0] * 1;
			var y = temp[1] * 1;
			if(cells.indexOf((x + 1) + "-" + y) != -1){
				if(cells.indexOf((x + 1) + "-" + (y - 1)) != -1){
					if(visitedEmptyCells.indexOf(x + "-" + (y - 1)) != -1){
						puzzleState = modifyCell(puzzleState, x, y - 1, "none", visitedEmptyCells, doingGuess);	
					}
				}
				if(cells.indexOf((x) + "-" + (y - 1)) != -1){
					if(visitedEmptyCells.indexOf((x + 1) + "-" + (y - 1)) != -1){
						puzzleState = modifyCell(puzzleState, x + 1, y - 1, "none", visitedEmptyCells, doingGuess);	
					}
				}
				if(cells.indexOf((x + 1) + "-" + (y + 1)) != -1){
					if(visitedEmptyCells.indexOf(x + "-" + (y + 1)) != -1){
						puzzleState = modifyCell(puzzleState, x, y + 1, "none", visitedEmptyCells, doingGuess);	
					}
				}
				if(cells.indexOf((x) + "-" + (y + 1)) != -1){
					if(visitedEmptyCells.indexOf((x + 1) + "-" + (y + 1)) != -1){
						puzzleState = modifyCell(puzzleState, x + 1, y + 1, "none", visitedEmptyCells, doingGuess);	
					}
				}
			}
		}
	}
	return puzzleState;
}
function checkAdjacentGroups(currentGroup, puzzleState, width, height){
	var currentCells = currentGroup.cells;
	var isValid = true;
	for(i = currentCells.length - 1; i > -1; i--) {
		var currentCell = currentCells[i];
		for (j = 0; j < groupsArray.length; j++) {
			var checkGroup = groupsArray[j];
			var checkCells = checkGroup.cells;
			if(checkGroup.size == currentGroup.size && checkGroup.id != currentGroup.id && isValid == true){
				for (k = 0; k < checkCells.length; k++) {
					var coords = checkCells[k].split("-");
					var x = coords[0] * 1;
					var y = coords[1] * 1;
					if((x + 1) + "-" + y == currentCell){
						isValid = false;
					}else if((x - 1) + "-" + y == currentCell){
						isValid = false;
					}else if(x + "-" + (y + 1) == currentCell){
						isValid = false;
					}else if(x + "-" + (y - 1) == currentCell){
						isValid = false;
					}
				}
				if(isValid == false){
					//console.log("ALERT");
					//console.log(currentGroup);
					//console.log(checkGroup);
				}
			}
		}
	}
	return isValid;
}
function addWall(puzzleState, width, height, x, y, visitedEmptyCells, doingGuess){

	if(puzzleState[x][y] == "-"){
		//console.log(wallGroupsArray);
		var maxWallCount = 0;
		var wallCount = 0;
		//if(wallGroupsArray.length == 1){
			
			var cellCount = 0;
			for (var x3=0;x3 < (height);x3++) {
				for (var y3=0; y3 < (width);y3++) {
					if(Number.isInteger(puzzleState[x3][y3] * 1)){
						cellCount += puzzleState[x3][y3] * 1;
					}
					if(puzzleState[x3][y3] == "#"){
						wallCount++;
					}
				}
			}
			var maxWallCount = (width * height) - cellCount;
			//console.log(maxWallCount + " " + wallGroupsArray[0].cells.length);
		//}
		if(wallCount < maxWallCount){
			puzzleState[x][y] = "#";

			//removes escapes from number groups
			for (j = 0; j < groupsArray.length; j++) {
				var group = groupsArray[j];
				var escapes = group.getEscapes();
				var index = escapes.indexOf(x + "-" + y);
				if(index != -1){
					escapes.splice(index, 1);
				}
			}

			//redoes wall groups
			var adjacentWallGroups = new Array();
			for (j = 0; j < wallGroupsArray.length; j++) {
				var currentWallGroup = wallGroupsArray[j];
				var currentWallCells = currentWallGroup.getCells();
				if(currentWallCells.indexOf((x + 1) + "-" + y) != -1){
					if(adjacentWallGroups.indexOf(currentWallGroup) == -1){
						adjacentWallGroups.push(currentWallGroup);
					}
				}else if(currentWallCells.indexOf((x - 1) + "-" + y) != -1){
					if(adjacentWallGroups.indexOf(currentWallGroup) == -1){
						adjacentWallGroups.push(currentWallGroup);
					}
				}else if(currentWallCells.indexOf(x + "-" + (y + 1)) != -1){
					if(adjacentWallGroups.indexOf(currentWallGroup) == -1){
						adjacentWallGroups.push(currentWallGroup);
					}
				}else if(currentWallCells.indexOf(x + "-" + (y - 1)) != -1){
					if(adjacentWallGroups.indexOf(currentWallGroup) == -1){
						adjacentWallGroups.push(currentWallGroup);
					}
				}
			}
			if(adjacentWallGroups.length == 0){
				//creates new wall group
				var newGroupCells = [x + "-" + y];
				var newGroupEscapes = new Array();
				if(x != height - 1 && puzzleState[x + 1][y] == "-"){
					newGroupEscapes.push((x + 1) + "-" + y);
				}
				if(x != 0 && puzzleState[x - 1][y] == "-"){
					newGroupEscapes.push((x - 1) + "-" + y);
				}
				if(y != width - 1 && puzzleState[x][y + 1] == "-"){
					newGroupEscapes.push(x + "-" + (y + 1));
				}
				if(y != 0 && puzzleState[x][y - 1] == "-"){
					newGroupEscapes.push(x + "-" + (y - 1));
				}
				/*
				if(visitedEmptyCells.indexOf((x + 1) + "-" + y) != -1){
					newGroupEscapes.push((x + 1) + "-" + y);	
				}
				if(visitedEmptyCells.indexOf((x - 1) + "-" + y) != -1){
					newGroupEscapes.push((x - 1) + "-" + y);
				}
				if(visitedEmptyCells.indexOf(x + "-" + (y + 1)) != -1){
					newGroupEscapes.push(x + "-" + (y + 1));
				}
				if(visitedEmptyCells.indexOf(x + "-" + (y - 1)) != -1){
					newGroupEscapes.push(x + "-" + (y - 1));	
				}*/
				var group = new groupObject("#", newGroupCells, newGroupEscapes, false, false, wallGroupsArray.length);
				wallGroupsArray.push(group);
			}else if(adjacentWallGroups.length == 1){
				//joins with existing group
				var addGroup = adjacentWallGroups[0];
				addGroup.addCell(x + "-" + y);
				var addGroupEscapes = addGroup.escapes;
				var index = addGroupEscapes.indexOf(x + "-" + y);
				addGroupEscapes.splice(index, 1);

				if(x != height - 1 && puzzleState[x + 1][y] == "-"){
					addGroupEscapes.push((x + 1) + "-" + y);
				}
				if(x != 0 && puzzleState[x - 1][y] == "-"){
					addGroupEscapes.push((x - 1) + "-" + y);
				}
				if(y != width - 1 && puzzleState[x][y + 1] == "-"){
					addGroupEscapes.push(x + "-" + (y + 1));
				}
				if(y != 0 && puzzleState[x][y - 1] == "-"){
					addGroupEscapes.push(x + "-" + (y - 1));
				}
				/*
				if(visitedEmptyCells.indexOf((x + 1) + "-" + y) != -1){
					addGroupEscapes.push((x + 1) + "-" + y);	
				}
				if(visitedEmptyCells.indexOf((x - 1) + "-" + y) != -1){
					addGroupEscapes.push((x - 1) + "-" + y);
				}
				if(visitedEmptyCells.indexOf(x + "-" + (y + 1)) != -1){
					addGroupEscapes.push(x + "-" + (y + 1));
				}
				if(visitedEmptyCells.indexOf(x + "-" + (y - 1)) != -1){
					addGroupEscapes.push(x + "-" + (y - 1));	
				}*/
			}else{
				//marks all joined groups as merged and creates new group
				var allWalls = new Array();
				var allEscapes = new Array();
				for (k = 0; k < adjacentWallGroups.length; k++) {
					var currentAdjacentGroup = adjacentWallGroups[k]
					allWalls.push.apply(allWalls, currentAdjacentGroup.getCells());
					allWalls.push(x + "-" + y);
					//console.log(allWalls);
					newWalls = Array.from(new Set(allWalls));
					//console.log(newWalls);
					allEscapes.push.apply(allEscapes, currentAdjacentGroup.getEscapes());
					
					var index = allEscapes.indexOf(x + "-" + y);

					allEscapes.splice(index, 1);

					if(x != height - 1 && puzzleState[x + 1][y] == "-"){
						if(allEscapes.indexOf((x + 1) + "-" + y) == -1){
							allEscapes.push((x + 1) + "-" + y);
						}
					}
					if(x != 0 && puzzleState[x - 1][y] == "-"){
						if(allEscapes.indexOf((x - 1) + "-" + y) == -1){
							allEscapes.push((x - 1) + "-" + y);
						}
					}
					if(y != width - 1 && puzzleState[x][y + 1] == "-"){
						if(allEscapes.indexOf(x + "-" + (y + 1)) == -1){
							allEscapes.push(x + "-" + (y + 1));
						}
					}
					if(y != 0 && puzzleState[x][y - 1] == "-"){
						if(allEscapes.indexOf(x + "-" + (y - 1)) == -1){
							allEscapes.push(x + "-" + (y - 1));
						}
					}
					/*
					if(visitedEmptyCells.indexOf((x + 1) + "-" + y) != -1){
						if(allEscapes.indexOf((x + 1) + "-" + y) == -1){
							allEscapes.push((x + 1) + "-" + y);
						}
					}
					if(visitedEmptyCells.indexOf((x - 1) + "-" + y) != -1){
						if(allEscapes.indexOf((x - 1) + "-" + y) == -1){
							allEscapes.push((x - 1) + "-" + y);
						}
					}
					if(visitedEmptyCells.indexOf(x + "-" + (y + 1)) != -1){
						if(allEscapes.indexOf(x + "-" + (y + 1)) == -1){
							allEscapes.push(x + "-" + (y + 1));
						}
					}
					if(visitedEmptyCells.indexOf(x + "-" + (y - 1)) != -1){
						if(allEscapes.indexOf(x + "-" + (y - 1)) == -1){
							allEscapes.push(x + "-" + (y - 1));
						}
					}*/
					newEscapes = Array.from(new Set(allEscapes));
					currentAdjacentGroup.isMerged = true;

				}
				var group = new groupObject("#", newWalls, newEscapes, false, false, wallGroupsArray.length);
				//console.log(group);
				wallGroupsArray.push(group);
			}
		}
	}
	return puzzleState;
}
function modifyCell(puzzleState, x, y, group, visitedEmptyCells, doingGuess){
	//x = x * 1;
	//y = y * 1;
	if(puzzleState != "*"){
		puzzleState[x][y] = "*";
		//console.log(x + "-" + y);
		var index = visitedEmptyCells.indexOf(x + "-" + y);
		if(index != -1){
			visitedEmptyCells.splice(index, 1);
		}
		var adjacentGroups = new Array();
		var groupIds = new Array();
		for (j = 0; j < groupsArray.length; j++) {
			if(groupsArray[j].isMerged == false){
				var currentAdjacentGroup = groupsArray[j];
				groupIds.push(currentAdjacentGroup.id * 1);
				var currentEscapes = currentAdjacentGroup.getEscapes();
				if(currentEscapes.indexOf(x + "-" + y) != -1){
					adjacentGroups.push(currentAdjacentGroup);
				}
			}
		}
		//console.log(adjacentGroups);
		groupIds.sort(function(a, b) {return a - b;});

		var lowestId = -1;
		var offset = groupIds[0];
		for (j = 0; j < groupIds.length; j++) {
			if (groupIds[j] != offset) {
				lowestId = offset;
				break;
			}
			offset++;
		}
		if (lowestId == -1) {
		    lowestId = groupIds[groupIds.length - 1] + 1;
		}
		//console.log(groupIds);
		//console.log(lowestId);
		var newCells = [x + "-" + y];
		var newEscapes = new Array();
		if(x != 0 && puzzleState[x - 1][y] == "-"){
			newEscapes.push((x - 1) + "-" + y);
		}
		if(x != height - 1 && puzzleState[x + 1][y] == "-"){
			newEscapes.push((x + 1) + "-" + y);
		}
		if(y != 0 && puzzleState[x][y - 1] == "-"){
			newEscapes.push(x + "-" + (y - 1));
		}
		if(y != width - 1 && puzzleState[x][y + 1] == "-"){
			newEscapes.push(x + "-" + (y + 1));
		}
		

		var size = "*";
		for (j = 0; j < adjacentGroups.length; j++) {
			if(adjacentGroups[j].size != "*"){
				size = adjacentGroups[j].size * 1;
			}
			adjacentGroups[j].isMerged = true;
			newCells.push.apply(newCells, adjacentGroups[j].getCells());
			newEscapes.push.apply(newEscapes, adjacentGroups[j].getEscapes());
		}
		newCells = Array.from(new Set(newCells));
		newEscapes = Array.from(new Set(newEscapes));

		var index = newEscapes.indexOf(x + "-" + y);
		if(index != -1){
			newEscapes.splice(index, 1);
		}
		//console.log(x + "-" + y);
		//console.log(newEscapes);
		var newGroup = new groupObject("*", newCells, newEscapes, false, false, lowestId);
		newGroup.cells = newCells.splice(0);
		newGroup.escapes = newEscapes.splice(0);
		if(size != "*"){
			newGroup.size = size + "";
		}
		if(newGroup.getCells().length == newGroup.size * 1){
			newGroup.isFinished = true;
			newGroup.escapes = new Array();
		}
		//console.log(newGroup);
		groupsArray.push(newGroup);
		//currentGroup = newGroup;
	}
	/*
	var foundAdjacentGroup = false;
	if(currentGroup == "none"){
		
		console.log("new group at " + x + "-" + y);
		
		for (j = 0; j < groupsArray.length; j++) {
			var currentAdjacentGroup = groupsArray[j];
			var currentEscapes = currentAdjacentGroup.getEscapes();
			if(currentEscapes.indexOf(x + "-" + y) != -1){
				foundAdjacentGroup = true;
				currentGroup = currentAdjacentGroup;
			}
		}
	}else{
		foundAdjacentGroup = true;
	}
	//if(foundAdjacentGroup == false){
	var newCells = [x + "-" + y];
	var newEscapes = new Array();
	if(x != 0 && puzzleState[x - 1][y] == "-"){
		newEscapes.push((x - 1) + "-" + y);
	}
	if(x != height - 1 && puzzleState[x + 1][y] == "-"){
		newEscapes.push((x + 1) + "-" + y);
	}
	if(y != 0 && puzzleState[x][y - 1] == "-"){
		newEscapes.push(x + "-" + (y - 1));
	}
	if(y != width - 1 && puzzleState[x][y + 1] == "-"){
		newEscapes.push(x + "-" + (y + 1));
	}
	var newGroup = new groupObject("*", newCells, newEscapes, false, false, groupsArray.length);
	groupsArray.push(newGroup);
	currentGroup = newGroup;
//}else{
	var adjacentGroups = new Array();
	var size = "*";
	for (j = 0; j < groupsArray.length; j++) {
		if(groupsArray[j] != currentGroup){
			if(groupsArray[j].escapes.indexOf(x + "-" + y) != -1){
				console.log("FUCK" + groupsArray[j].size);
				if(groupsArray[j].size != "*"){

					size = groupsArray[j].size;
				}
				adjacentGroups.push(groupsArray[j]);
			}
		}
	}
	if(adjacentGroups.length > 0){
		
		currentGroup.addCell(x + "-" + y);
		var newCells = currentGroup.getCells();
		var newEscapes = currentGroup.getEscapes();
		for (j = 0; j < adjacentGroups.length; j++) {
			//if(adjacentGroups[j].size != "*"){

			//}else{
				adjacentGroups[j].isMerged = true;
			//}
			newCells.push.apply(newCells, adjacentGroups[j].getCells());
			newEscapes.push.apply(newEscapes, adjacentGroups[j].getEscapes());
		}

		if(x != 0 && puzzleState[x - 1][y] == "-"){
			newEscapes.push((x - 1) + "-" + y);
		}
		if(x != height - 1 && puzzleState[x + 1][y] == "-"){
			newEscapes.push((x + 1) + "-" + y);
		}
		if(y != 0 && puzzleState[x][y - 1] == "-"){
			newEscapes.push(x + "-" + (y - 1));
		}
		if(y != width - 1 && puzzleState[x][y + 1] == "-"){
			newEscapes.push(x + "-" + (y + 1));
		}

		newCells = Array.from(new Set(newCells));
		newEscapes = Array.from(new Set(newEscapes));
		var index = newEscapes.indexOf(x + "-" + y);
		if(index != -1){
			newEscapes.splice(index, 1);
		}
		currentGroup.cells = newCells.splice(0);
		currentGroup.escapes = newEscapes.splice(0);
		//console.log(size);
		currentGroup.size = size;
		if(currentGroup.getCells().length == currentGroup.size){
			currentGroup.isFinished = true;
			currentGroup.escapes = new Array();
		}
	}else{
		if(currentGroup.cells.indexOf((x + "-" + y) == -1)){
			//console.log("modifying");
			if(doingGuess == false){
				postMessage("solving " + x + "-" + y);
			}
			
			currentGroup.addCell(x + "-" + y);
			var index = visitedEmptyCells.indexOf(x + "-" + y);
			if(index != -1){
				visitedEmptyCells.splice(index, 1);
			}
			//modify escapes for group	
			var tempEscapes = currentGroup.escapes.splice(0);
			var index = tempEscapes.indexOf(x + "-" + y);
			if(index != -1){
				tempEscapes.splice(index, 1);
			}
			//console.log(tempEscapes);

			if(visitedEmptyCells.indexOf((x + 1) + "-" + y) != -1){
				if(tempEscapes.indexOf((x + 1) + "-" + y) == -1){
					tempEscapes.push((x + 1) + "-" + y);
				}
			}
			if(visitedEmptyCells.indexOf((x - 1) + "-" + y) != -1){
				if(tempEscapes.indexOf((x - 1) + "-" + y) == -1){
					tempEscapes.push((x - 1) + "-" + y);
				}
			}
			if(visitedEmptyCells.indexOf(x + "-" + (y + 1)) != -1){
				if(tempEscapes.indexOf(x + "-" + (y + 1)) == -1){
					tempEscapes.push(x + "-" + (y + 1));
				}
			}
			if(visitedEmptyCells.indexOf(x + "-" + (y - 1)) != -1){
				if(tempEscapes.indexOf(x + "-" + (y - 1)) == -1){
					tempEscapes.push(x + "-" + (y - 1));
				}
			}
			//console.log(tempEscapes);
			currentGroup.escapes = tempEscapes;
			//currentGroup.cells = Array.from(new Set(currentGroup.cells));
			//console.log(groupsArray);
			if(currentGroup.getCells().length == currentGroup.size){
				currentGroup.isFinished = true;
				currentGroup.escapes = new Array();
			}

		}
	}
	//}*/
	return puzzleState;
}

function replaceEscapes(currentGroup, puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess){
	var escapes = currentGroup.escapes;
	var cells = currentGroup.cells;
	var invalidEscapes = new Array();
	//console.log(visitedEmptyCells);
	//console.log(escapes);
	for (i = 0; i < cells.length; i++) {

		var coords = cells[i].split("-");
		var cellx = coords[0] * 1;
		var celly = coords[1] * 1;
		if(visitedEmptyCells.indexOf((cellx + 1) + "-" + celly) != -1 && escapes.indexOf((cellx + 1) + "-" + celly) == -1){
			invalidEscapes.push((cellx + 1) + "-" + celly);
			//console.log((cellx + 1) + "-" + celly  + currentGroup);
		}
		if(visitedEmptyCells.indexOf((cellx - 1) + "-" + celly) != -1 && escapes.indexOf((cellx - 1) + "-" + celly) == -1){
			invalidEscapes.push((cellx - 1) + "-" + celly);
			//console.log((cellx - 1) + "-" + celly  + currentGroup);
		}
		if(visitedEmptyCells.indexOf(cellx + "-" + (celly + 1)) != -1 && escapes.indexOf(cellx + "-" + (celly + 1)) == -1){
			invalidEscapes.push(cellx + "-" + (celly + 1));
			//console.log(cellx + "-" + (celly + 1) + currentGroup);
		}
		if(visitedEmptyCells.indexOf(cellx + "-" + (celly - 1)) != -1 && escapes.indexOf(cellx + "-" + (celly - 1)) == -1){
			invalidEscapes.push(cellx + "-" + (celly - 1));
			//console.log(cellx + "-" + (celly - 1) + currentGroup);
		}
	}
	//console.log(invalidEscapes);
	//var invalidEscapes = new Array();
	for (i = 0; i < escapes.length; i++) {
		var escape = escapes[i];
		var coords = escape.split("-");
		var escapex = coords[0] * 1;
		var escapey = coords[1] * 1;
		var temp = currentGroup.cells[0];
		coords = temp.split("-");
		var startx = coords[0] * 1;
		var starty = coords[1] * 1;
		puzzleState[escapex][escapey] = "1";
		//something to not travel through removed escapes??????
		var isValid = validFillCells(width, height, startx, starty, puzzleState, currentGroup.size, invalidEscapes);
		if(isValid == false){
			//console.log("FOUND" + escapex + "-" + escapey);
			//puzzleState[escapex][escapey] = "-";
			puzzleState = modifyCell(puzzleState, escapex, escapey, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
		}else{
			//console.log("NOT FOUND" + escapex + "-" + escapey);
			puzzleState[escapex][escapey] = "-";
		}
	}
	return puzzleState;
}
function validFillCells(width, height, xCoord, yCoord, puzzleState, number, invalidEscapes){
	var visitedCells = new Array();
	var x = xCoord;
	var y = yCoord;
	var continueTraveling = true;
	var isValidFill = true;
	while(continueTraveling == true){
		if(visitedCells.indexOf(x + "-" + y) == -1){
			visitedCells.push(x + "-" + y);
		}
		if(visitedCells.length >= (number * 1)){
			continueTraveling = false;
			isValidFill = true;
		}
		x = x * 1;
		y = y * 1;
		if(x != height - 1 && (puzzleState[x + 1][y] == number || puzzleState[x + 1][y] == "-") && visitedCells.indexOf((x + 1) + "-" + y) == -1 && invalidEscapes.indexOf((x + 1) + "-" + y) == -1){
			x++;
		}else if(x != 0 && (puzzleState[x - 1][y] == number || puzzleState[x - 1][y] == "-") && visitedCells.indexOf((x - 1) + "-" + y) == -1 && invalidEscapes.indexOf((x - 1) + "-" + y) == -1){
			x--;
		}else if(y != width - 1 && (puzzleState[x][y + 1] == number || puzzleState[x][y + 1] == "-") && visitedCells.indexOf(x + "-" + (y + 1)) == -1 && invalidEscapes.indexOf(x + "-" + (y + 1)) == -1){
			y++;
		}else if(y != 0 && (puzzleState[x][y - 1] == number || puzzleState[x][y - 1] == "-") && visitedCells.indexOf(x + "-" + (y - 1)) == -1 && invalidEscapes.indexOf(x + "-" + (y - 1)) == -1){
			y--;
		}else{
			var index = visitedCells.indexOf(x + "-" + y);
			if (index != 0){
				var lastCell = visitedCells[index - 1].split("-");
				x = lastCell[0];
				y = lastCell[1];

			}else{
				continueTraveling = false;
			}
		}
	}
	if(visitedCells.length < (number * 1)){
		isValidFill = false;
	}
	return isValidFill;
}

function tooSmallEmptyGroup(currentGroup, puzzleState, width, height, visitedEmptyCells, visitedEmptyGroups, doingGuess){
	var accessibleEmptyGroups = new Array();
	var accessibleEmptyGroupsEscapes = new Array();
	var accessibleEmptyGroupsCells = new Array();
	var isValidEmptyGroups = new Array();
	var groupEscapes = currentGroup.escapes;
	//if(groupEscapes.length == 2){
	for (i = 0; i < groupEscapes.length; i++) {
		for (j = 0; j < visitedEmptyGroups.length; j++) {
			var emptyGroupCells = visitedEmptyGroups[j];
			if(emptyGroupCells.indexOf(groupEscapes[i]) != -1){
				if(accessibleEmptyGroups.indexOf(visitedEmptyGroups[j]) == -1){
					accessibleEmptyGroups.push(visitedEmptyGroups[j]);
					accessibleEmptyGroupsCells.push(emptyGroupCells);
					accessibleEmptyGroupsEscapes.push(groupEscapes[i]);
					var validFill = true;
					for (l = 0; l < groupsArray.length; l++) {
						var checkGroup = groupsArray[l];
						var checkEscapes = checkGroup.escapes;
						if(checkGroup.size == currentGroup.size && checkGroup.id != currentGroup.id && validFill == true && checkGroup.isMerged == false){
							for (z = 0; z < emptyGroupCells.length; z++) {
								if(checkEscapes.indexOf(emptyGroupCells[z]) != -1){
									validFill = false;
								}
							}
						}
					}
					isValidEmptyGroups.push(validFill);
				}
				//totalAccessibleCells.push.apply(totalAccessibleCells, emptyGroupCells);
				//foundEmpty = true;
			}
		}
	}
	if(groupEscapes.length == 2){
		if(accessibleEmptyGroups.length == 2){
			if(isValidEmptyGroups[0] == true && accessibleEmptyGroups[0].length < currentGroup.size - currentGroup.cells.length){
				//console.log("FOUND" + accessibleEmptyGroupsEscapes[1]);
				var coords = accessibleEmptyGroupsEscapes[1].split("-");
				var modifyx = coords[0] * 1;
				var modifyy = coords[1] * 1;
				puzzleState = modifyCell(puzzleState, modifyx, modifyy, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
			}
			if(isValidEmptyGroups[1] == true && accessibleEmptyGroups[1].length < currentGroup.size - currentGroup.cells.length){
				//console.log("FOUND" + accessibleEmptyGroupsEscapes[0]);
				var coords = accessibleEmptyGroupsEscapes[0].split("-");
				var modifyx = coords[0] * 1;
				var modifyy = coords[1] * 1;
				puzzleState = modifyCell(puzzleState, modifyx, modifyy, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
			}
		}
	}else if(groupEscapes.length == 3){
		if(accessibleEmptyGroups.length == 3){
			if(isValidEmptyGroups[0] == true && isValidEmptyGroups[1] == true && (accessibleEmptyGroups[0].length + accessibleEmptyGroups[1].length) < currentGroup.size - currentGroup.cells.length){
				//console.log("FOUND" + accessibleEmptyGroupsEscapes[1]);
				var coords = accessibleEmptyGroupsEscapes[2].split("-");
				var modifyx = coords[0] * 1;
				var modifyy = coords[1] * 1;
				puzzleState = modifyCell(puzzleState, modifyx, modifyy, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
			}
			if(isValidEmptyGroups[0] == true && isValidEmptyGroups[2] == true && (accessibleEmptyGroups[0].length + accessibleEmptyGroups[2].length) < currentGroup.size - currentGroup.cells.length){
				//console.log("FOUND" + accessibleEmptyGroupsEscapes[1]);
				var coords = accessibleEmptyGroupsEscapes[1].split("-");
				var modifyx = coords[0] * 1;
				var modifyy = coords[1] * 1;
				puzzleState = modifyCell(puzzleState, modifyx, modifyy, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
			}
			if(isValidEmptyGroups[1] == true && isValidEmptyGroups[2] == true && (accessibleEmptyGroups[1].length + accessibleEmptyGroups[2].length) < currentGroup.size - currentGroup.cells.length){
				//console.log("FOUND" + accessibleEmptyGroupsEscapes[1]);
				var coords = accessibleEmptyGroupsEscapes[0].split("-");
				var modifyx = coords[0] * 1;
				var modifyy = coords[1] * 1;
				puzzleState = modifyCell(puzzleState, modifyx, modifyy, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
			}
		}else if(accessibleEmptyGroups.length == 2){
			//console.log("FUCK" + currentGroup.toString());
			if(isValidEmptyGroups[0] == true && accessibleEmptyGroups[0].length < currentGroup.size - currentGroup.cells.length){
				if(accessibleEmptyGroupsCells[0].indexOf(groupEscapes[0]) != -1 && accessibleEmptyGroupsCells[0].indexOf(groupEscapes[1]) != -1){
					//console.log(accessibleEmptyGroupsCells[0]);
					//console.log(groupEscapes[2]);
					//console.log(accessibleEmptyGroupsCells[0].indexOf(groupEscapes[2]) );
					var coords = groupEscapes[2].split("-");
					var modifyx = coords[0] * 1;
					var modifyy = coords[1] * 1;
					//console.log("LOL" + currentGroup.size + " " + modifyx + "-" + modifyy);
					puzzleState = modifyCell(puzzleState, modifyx, modifyy, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
				}else if(accessibleEmptyGroupsCells[0].indexOf(groupEscapes[1]) != -1 && accessibleEmptyGroupsCells[0].indexOf(groupEscapes[2]) != -1){
					//console.log(accessibleEmptyGroupsCells[0]);
					//console.log(groupEscapes[2]);
					//console.log(accessibleEmptyGroupsCells[0].indexOf(groupEscapes[2]) );
					var coords = groupEscapes[0].split("-");
					var modifyx = coords[0] * 1;
					var modifyy = coords[1] * 1;
					//console.log("LOL" + currentGroup.size + " " + modifyx + "-" + modifyy);
					puzzleState = modifyCell(puzzleState, modifyx, modifyy, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
				}else if(accessibleEmptyGroupsCells[0].indexOf(groupEscapes[0]) != -1 && accessibleEmptyGroupsCells[0].indexOf(groupEscapes[2]) != -1){
					//console.log(accessibleEmptyGroupsCells[0]);
					//console.log(groupEscapes[2]);
					//console.log(accessibleEmptyGroupsCells[0].indexOf(groupEscapes[2]) );
					var coords = groupEscapes[1].split("-");
					var modifyx = coords[0] * 1;
					var modifyy = coords[1] * 1;
					//console.log("LOL" + currentGroup.size + " " + modifyx + "-" + modifyy);
					puzzleState = modifyCell(puzzleState, modifyx, modifyy, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
				}
			}else if(isValidEmptyGroups[1] == true && accessibleEmptyGroups[1].length < currentGroup.size - currentGroup.cells.length){
				if(accessibleEmptyGroupsCells[1].indexOf(groupEscapes[0]) != -1 && accessibleEmptyGroupsCells[1].indexOf(groupEscapes[1]) != -1){
					//console.log(accessibleEmptyGroupsCells[0]);
					//console.log(groupEscapes[2]);
					//console.log(accessibleEmptyGroupsCells[0].indexOf(groupEscapes[2]) );
					var coords = groupEscapes[2].split("-");
					var modifyx = coords[0] * 1;
					var modifyy = coords[1] * 1;
					//console.log("LOL" + currentGroup.size + " " + modifyx + "-" + modifyy);
					puzzleState = modifyCell(puzzleState, modifyx, modifyy, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
				}else if(accessibleEmptyGroupsCells[1].indexOf(groupEscapes[1]) != -1 && accessibleEmptyGroupsCells[1].indexOf(groupEscapes[2]) != -1){
					//console.log(accessibleEmptyGroupsCells[0]);
					//console.log(groupEscapes[2]);
					//console.log(accessibleEmptyGroupsCells[0].indexOf(groupEscapes[2]) );
					var coords = groupEscapes[0].split("-");
					var modifyx = coords[0] * 1;
					var modifyy = coords[1] * 1;
					//console.log("LOL" + currentGroup.size + " " + modifyx + "-" + modifyy);
					puzzleState = modifyCell(puzzleState, modifyx, modifyy, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
				}else if(accessibleEmptyGroupsCells[1].indexOf(groupEscapes[0]) != -1 && accessibleEmptyGroupsCells[1].indexOf(groupEscapes[2]) != -1){
					//console.log(accessibleEmptyGroupsCells[0]);
					//console.log(groupEscapes[2]);
					//console.log(accessibleEmptyGroupsCells[0].indexOf(groupEscapes[2]) );
					var coords = groupEscapes[1].split("-");
					var modifyx = coords[0] * 1;
					var modifyy = coords[1] * 1;
					//console.log("LOL" + currentGroup.size + " " + modifyx + "-" + modifyy);
					puzzleState = modifyCell(puzzleState, modifyx, modifyy, currentGroup.size, currentGroup, visitedEmptyCells, doingGuess);
				}
			}
		}
	}

		//console.log(accessibleEmptyGroups);
		//console.log(accessibleEmptyGroupsEscapes);
		//console.log(isValidEmptyGroups);
	
	return puzzleState;
}

function sharedEscape(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess){
	var groupEscapes = currentGroup.escapes;

	for(i = groupEscapes.length - 1; i > -1; i--) {
		var escapeGroups = new Array();
		var totalSize = currentGroup.cells.length + 1;
		for (j = 0; j < groupsArray.length; j++) {
			var checkGroup = groupsArray[j];
			var checkEscapes = checkGroup.escapes;
			if(checkGroup.size == currentGroup.size && checkGroup.id != currentGroup.id){
				
				var index = checkEscapes.indexOf(groupEscapes[i]);
				if(index != -1 && checkGroup.isMerged == false && currentGroup.isMerged == false){
					totalSize += checkGroup.cells.length;
					escapeGroups.push(checkGroup);
					/*
					if(checkGroup.cells.length + currentGroup.cells.length + 1 > currentGroup.size && checkGroup.isMerged == false && currentGroup.isMerged == false){
						
						groupEscapes.splice(i, 1);
						checkEscapes.splice(index, 1);
						
						//console.log(currentGroup.size);
						//if(currentGroup.size == 6){
							///console.log("WHY" + checkEscapes[index]);
							//console.log("WHY" + groupEscapes[i]);
							//console.log(currentGroup);
							//console.log(checkGroup);
						//}
					}*/
				}
			}
		}
		//console.log(totalSize + " " + currentGroup.size);
		if(totalSize > currentGroup.size){
			//console.log(escapeGroups);
			
			for (k = 0; k < escapeGroups.length; k++) {

				var checkEscapes = escapeGroups[k].escapes;
				var index = checkEscapes.indexOf(groupEscapes[i]);
				//console.log(checkEscapes);
				//console.log(groupEscapes[i]);
				if(index != -1){
					//console.log("what " + index);
					//console.log(checkEscapes);
					
					//console.log("removing escape " + checkEscapes[index]);
					checkEscapes.splice(index, 1);
				}
			}

			currentGroup.escapes.splice(i, 1);
		}
	}
	return puzzleState;
}
function escapeFinished(currentGroup, puzzleState, width, height, visitedEmptyCells, doingGuess){
	var finishedGroupCells = new Array();
	var groupEscapes = currentGroup.escapes;
	for (j = 0; j < groupsArray.length; j++) {
		var checkGroup = groupsArray[j];
		if(checkGroup.size == currentGroup.size && checkGroup.id != currentGroup.id && checkGroup.isFinished == true){
			finishedGroupCells.push.apply(finishedGroupCells, checkGroup.cells);
		}
	}
	for(i = groupEscapes.length - 1; i > -1; i--) {
		var coords = groupEscapes[i].split("-");
		var x = coords[0] * 1;
		var y = coords[1] * 1;
		var foundTouch = false;
		if(finishedGroupCells.indexOf((x + 1) + "-" + y) != -1){
			foundTouch = true;
		}
		if(finishedGroupCells.indexOf((x - 1) + "-" + y) != -1){
			foundTouch = true;
		}
		if(finishedGroupCells.indexOf(x + "-" + (y + 1)) != -1){
			foundTouch = true;
		}
		if(finishedGroupCells.indexOf(x + "-" + (y - 1)) != -1){
			foundTouch = true;
		}
		if(foundTouch == true){
			//console.log(groupEscapes[i]);
			groupEscapes.splice(i, 1);
		}
	}
	return puzzleState;
}
function groupObject(size, cells, escapes, finished, merged, id){
	this.size = size;
	this.cells = cells;
	this.escapes = escapes;
	this.isFinished = finished;
	this.isMerged = merged;
	this.id = id
	groupObject.prototype.createClone = function(){
		var newClone = new groupObject(this.size, this.cells.splice(0), this.escapes.splice(0), this.isFinished, this.isMerged, this.id);
		return newClone;
	}
	groupObject.prototype.toString = function(){
		return this.size + "-" + this.cells + "-" + this.isFinished;
	}
	groupObject.prototype.getSize = function(){
        return this.size;
    }
    groupObject.prototype.getCells = function(){
        return this.cells;
    }
    groupObject.prototype.getEscapes = function(){
        return this.escapes;
    }
    groupObject.prototype.getIsFinished = function(){
        return this.isFinished;
    }
    groupObject.prototype.getIsMerged = function(){
        return this.isMerged;
    }
    groupObject.prototype.getId = function(){
        return this.id;
    }
    groupObject.prototype.addCell = function(value){
        this.cells.push(value);
    }
    groupObject.prototype.addEscape = function(value){
        this.escapes.push(value);
    }
}
function puzzleObject(puzzString){
	this.puzzleString = puzzString;
	splitPuzz = puzzString.split(":", 2);
	puzzData = splitPuzz[1];
	wxh = splitPuzz[0].split("x");
	this.width = wxh[0];
	this.height = wxh[1];
	puzzData2 = puzzData.split(",");
	this.puzzleState = new Array(this.height);
	for(var i=0;i<=(this.height) - 1;i++){
		this.puzzleState[i] = new Array(this.width);
	}
    var z = 0;
	for (var x=0;x < this.height;x++) {
		for (var y=0; y < this.width;y++) {
			this.puzzleState[x][y] = puzzData2[z];
			z++;
		}
	}
	puzzleObject.prototype.getHeight = function(){
		return this.height;
	};
	puzzleObject.prototype.getWidth = function(){
		return this.width;
	};
	puzzleObject.prototype.getPuzzleState = function(){
		return this.puzzleState;
	};
}


function countArray(array, check){
	var count = 0;
	for(var i = 0; i < array.length; i++){
	    if(array[i] == check){
		    count++;
		}
	}
	return count;
}
function checkAdjacent(cell1, cell2){
	var isAdjacent = false;
	var coords1 = cell1.split("-");
	var x = coords1[0] * 1;
	var y = coords1[1] * 1;
	if(((x + 1) + "-" + y == cell2) || ((x - 1) + "-" + y == cell2) || (x + "-" + (y + 1) == cell2) || (x + "-" + (y - 1) == cell2)){
		isAdjacent = true;
	}
	return isAdjacent;
}
/** If this array contains key, returns the index of
 * the first occurrence of key; otherwise returns -1. */
Array.prototype.linearSearch = function(key, compare) {
    if (typeof(compare) == 'undefined') {
        compare = ascend;
    }
    for (var i = 0;  i < this.length;  i++) {
        if (compare(this[i], key) == 0) {
            return i;
        }
    }
    return -1;
}


/** If this array contains key, returns the index of any
 * occurrence of key; otherwise returns -insertion - 1,
 * where insertion is the location within the array at
 * which the key should be inserted.  binarySearch assumes
 * this array is already sorted. */
Array.prototype.binarySearch = function(key, compare) {
    if (typeof(compare) == 'undefined') {
        compare = ascend;
    }
    var left = 0;
    var right = this.length - 1;
    while (left <= right) {
        var mid = left + ((right - left) >>> 1);
        var cmp = compare(key, this[mid]);
        if (cmp > 0)
            left = mid + 1;
        else if (cmp < 0)
            right = mid - 1;
        else
            return mid;
    }
    return -(left + 1);
}

/** Adds all the elements in the
 * specified arrays to this array. */
Array.prototype.addAll = function() {
    for (var a = 0;  a < arguments.length;  a++) {
        arr = arguments[a];
        for (var i = 0;  i < arr.length;  i++) {
            this.push(arr[i]);
        }
    }
}


/** Retains in this array all the elements
 * that are also found in the specified array. */
Array.prototype.retainAll = function(arr, compare) {
    if (typeof(compare) == 'undefined') {
        compare = ascend;
    }
    var i = 0;
    while (i < this.length) {
        if (arr.linearSearch(this[i], compare) == -1) {
            var end = i + 1;
            while (end < this.length &&
                    arr.linearSearch(this[end], compare) == -1) {
                end++;
            }
            this.splice(i, end - i);
        }
        else {
            i++;
        }
    }
}


/** Removes from this array all the elements
 * that are also found in the specified array. */
Array.prototype.removeAll = function(arr, compare) {
    if (typeof(compare) == 'undefined') {
        compare = ascend;
    }
    var i = 0;
    while (i < this.length) {
        if (arr.linearSearch(this[i], compare) != -1) {
            var end = i + 1;
            while (end < this.length &&
                    arr.linearSearch(this[end], compare) != -1) {
                end++;
            }
            this.splice(i, end - i);
        }
        else {
            i++;
        }
    }
}


/** Makes all elements in this array unique.  In other
 * words, removes all duplicate elements from this
 * array.  Assumes this array is already sorted. */
Array.prototype.unique = function(compare) {
    if (typeof(compare) == 'undefined') {
        compare = ascend;
    }
    var dst = 0;  // Destination for elements
    var src = 0;  // Source of elements
    var limit = this.length - 1;
    while (src < limit) {
        while (compare(this[src], this[src + 1]) == 0) {
            if (++src == limit) {
                break;
            }
        }
        this[dst++] = this[src++];
    }
    if (src == limit) {
        this[dst++] = this[src];
    }
    this.length = dst;
}


/** Compares two objects using
 * built-in JavaScript operators. */
function ascend(a, b) {
    if (a < b)
        return -1;
    else if (a > b)
        return 1;
    return 0;
}
function shuffle(array) {
    for (var i=array.length - 1; i > -1;i--) {
        var index = (Math.random() * i) | 0;
        var temp = array[i];
        array[i] = array[index];
        array[index] = temp;
    }
    return array;
}