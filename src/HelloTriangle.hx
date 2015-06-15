package ;

import openfl.display.Sprite;
import openfl.display3D._shaders.AGLSLShaderUtils;
import openfl.display3D._shaders.Shader;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.events.Event;
import openfl.geom.Matrix3D;
import openfl.utils.AGALMiniAssembler;
import openfl.utils.ByteArray;
import openfl.Vector;

/**
 * In this practice we simply draw a simple triangle using only
 * Stage3D API and nothing more.
 * You should be able to write this class on your own before
 * going any further.
 * 
 * Find the associate tutorial at my blog on http://blog.norbz.net/
 * @see http://blog.norbz.net/2012/01/stage3d-agal-from-scratch-part-iii-hello-triangle
 * 
 * 
 * @author Nicolas CHESNE
 * 			http://blog.norbz.net
 * 			http://www.norbz.fr
 */
class HelloTriangle extends Sprite {

	// simple width and height quick accessors
	private var W:Int;
	private var H:Int;
	
	// Stage3D related members
	private var context:Context3D;
	private var program:Program3D;
	private var vertexBuffer:VertexBuffer3D;
	private var indexBuffer:IndexBuffer3D;
	private var m:Matrix3D;

	private var vertexShader:Shader;
	private var fragmentShader:Shader;

	/**
	 * CLASS CONSTRUCTOR
	 */
	public function new() {
		super();
		// Init the practive when the stage is available
		if (stage!=null) __init();
		else addEventListener(Event.ADDED_TO_STAGE, __init);
	}
	
	/**
	 * Initialise the practice by requesting a Context3D to the first Stage3D
	 * Remember than when working with Stage3D you are actually working with Context3D
	 */
	private function __init(event:Event = null):Void {
		removeEventListener(Event.ADDED_TO_STAGE, __init);

		W = stage.stageWidth;
		H = stage.stageHeight;

		// wait for Stage3D to provide us a Context3D
		stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, __onCreate);
		stage.stage3Ds[0].requestContext3D();
	}
	
	/**
	 * Called when the context3D has been created
	 * 
	 * Put the whole scene in place for the GPU.
	 * As you can see, I chose to first deal with the whole Allocation thing
	 * before dealin with the upload things, but I could have first create buffers and upload them
	 * before doing the same for the program.
	 */
	private function __onCreate(event:Event):Void {
		// // // CREATE CONTEXT // 

		context = stage.stage3Ds[0].context3D;
		
		// By enabling the Error reporting, you can get some valuable information about errors in your shaders
		// But it also dramatically slows down your program.
		// context.enableErrorChecking=true;
		
		// Configure the back buffer, in width and height. You can also specify the antialiasing
		// The backbuffer is the memory space where your final image is rendered.
		context.configureBackBuffer(W, H, 4, true);
		
		
		// Allocation - program compilation
		__createBuffers();
		__createAndCompileProgram();
		
		// Upload program and buffers data
		__uploadProgram();
		__uploadBuffers();
		
		// Split chunk of data and set active program
		__splitAndMakeChunkOfDataAvailableToProgram();
		__setActiveProgram();
		
		// start the rendering loop
		#if flash
			addEventListener(Event.ENTER_FRAME, render);
		#else
			context.setRenderMethod(render);
		#end
	}
	
	/**
	 * Create the vertex and index buffers
	 */	private function __createBuffers():Void {

		// // // CREATE BUFFERS // //
		vertexBuffer = context.createVertexBuffer(3, 6);
		indexBuffer = context.createIndexBuffer(3);
	}

	/**
	 * Upload some data to the vertex and index buffers
	 */
	private function __uploadBuffers():Void {
		var vertexData:Vector<Float>=Vector.ofArray([
		-1, -1, 0, 1, 0, 0, 	// - 1st vertex x,y,z,r,g,b 
		0, 1, 0, 0, 1, 0, 		// - 2nd vertex x,y,z,r,g,b 
		1, -1, 0, 0, 0, 1		// - 3rd vertex x,y,z,r,g,b
		]);
		
		vertexBuffer.uploadFromVector(vertexData, 0, 3);
		var index:Vector<UInt> = new Vector();
		index.push(0);
		index.push(1);
		index.push(2);
		indexBuffer.uploadFromVector(index, 0, 3);
	}
	
	/**
	 * Define how each Chunck of Data should be split and upload to fast access register for our AGAL program
	 * 
	 * @see __createAndCompileProgram
	 */
	private function __splitAndMakeChunkOfDataAvailableToProgram():Void {
		// So here, basically, your telling your GPU that for each Vertex with a vertex being x,y,y,r,g,b
		// you will copy in register "0", from the buffer "vertexBuffer, starting from the postion "0" the FLOAT_3 next number
		context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // register "0" now contains x,y,z
		
		// Here, you will copy in register "1" from "vertexBuffer", starting from index "3", the next FLOAT_3 numbers
		context.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3); // register 1 now contains r,g,b
	}

	/**
	 * Create the program that will run in your GPU.
	 */
	private function __createAndCompileProgram() : Void {
		// // // CREATE SHADER PROGRAM // //
		// When you call the createProgram method you are actually allocating some V-Ram space
		// for your shader program.
		program = context.createProgram();
		
		
		// VERTEX SHADER
		var code:String = "";
		code += "mov op, va0\n"; // Move the Vertex Attribute 0 (va0), which is our Vertex Coordinate, to the Output Point
		code += "mov v0, va1\n"; // Move the Vertex Attribute 1 (va1), which is our Vertex Color, to the variable register v0
								 // Variable register are memory space shared between your Vertex Shader and your Fragment Shader
								 
		// Compile our AGAL Code into ByteCode using the MiniAssembler 
		vertexShader = AGLSLShaderUtils.createShader(Context3DProgramType.VERTEX, code);
		
		code = "mov oc, v0\n"; // Move the Variable register 0 (v0) where we copied our Vertex Color, to the output color
		
		// Compile our AGAL Code into Bytecode using the MiniAssembler
		fragmentShader = AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, code);
	}
	
	/**
	 * Upload our two compiled shaders into the graphic card.
	 */
	private function __uploadProgram():Void {
		// UPLOAD TO GPU PROGRAM
		program.upload(vertexShader, fragmentShader); // Upload the combined program to the video Ram
	}
	
	/**
	 * Define the active program to run on our GPU
	 */
	private function __setActiveProgram():Void {
		// Set our program as the current active one
		context.setProgram(program);
	}

	/**
	 * Called each frame
	 * Render the scene
	 */
	private function render(event:Event):Void {
		context.clear(0,1,0); // Clear the backbuffer by filling it with the given color
		
		context.drawTriangles(indexBuffer); // Draw the triangle according to the indexBuffer instructions into the backbuffer
		context.present(); // render the backbuffer on screen.
	}
}

