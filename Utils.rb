include Math
require './Matrix.rb'
require './MatrixUtils.rb'
require './VectorUtils.rb'

module Utils

  def self.restrict(n, bot: 0, top: 255)
    return [[n, top].min, bot].max
  end

  # Calculates light at a point using Phong Reflection Model
  def self.calc_light(view, normal)
    v = VectorUtils.normalize(view)
    n = VectorUtils.normalize(normal)
    l = VectorUtils.normalize($POINT_LIGHT[0])

    ambient = $AMBIENT_LIGHT.zip($Ka).map{|x, y| x * y}
    diffuse = $POINT_LIGHT[1].zip($Kd).map{|x, y| x * y}
    specular = $POINT_LIGHT[1].zip($Ks).map{|x, y| x * y}
    costheta = VectorUtils.dot_product(l, n)
    temp = VectorUtils.dot_product(n, l)
    cosalpha = [VectorUtils.dot_product(n.map{|a| a*temp*2}.zip(l).map{|a, b| a - b}, v), 0].max**8

    diffuse  = diffuse.map{|x| x*costheta}
    specular = specular.map{|x| x*cosalpha}

    return specular.zip(ambient.zip(diffuse).map{|x, y| x + y}).map{|x, y| x + y}.map{|x| restrict(x)} #exhales slowly
  end

  def self.write_out(file: $OUTFILE)
    $SCREEN.write_out(file: file)
  end

  def self.display(tempfile: $TEMPFILE)
    write_out(file: tempfile)
    puts %x[display #{tempfile}]
    puts %x[rm #{tempfile}]
  end

  def self.parse_file(filename: $INFILE)
    file = File.new(filename, "r")
    while (line = file.gets)
      line = line.chomp #Kill trailing newline
      puts "Executing command: \"" + line + '"' if $DEBUGGING
      case line
      when "line"
        args = file.gets.chomp.split(" ")
        for i in (0...6); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        temp = Matrix.new(4,0)
        temp.add_col([args[0], args[1], args[2], 1])
        temp.add_col([args[3], args[4], args[5], 1])
        MatrixUtils.multiply($COORDSYS.peek(), temp)
        Draw.push_edge_matrix(temp)
      when "circle"
        args = file.gets.chomp.split(" ")
        for i in (0...4); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        temp = Matrix.new(4, 0)
        Draw.circle(args[0], args[1], args[2], args[3], temp)
        MatrixUtils.multiply($COORDSYS.peek(), temp)
        Draw.push_edge_matrix(temp)
      when "hermite"
        args = file.gets.chomp.split(" ")
        for i in (0...8); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        temp = Matrix.new(4, 0)
        Draw.hermite(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], temp)
        MatrixUtils.multiply($COORDSYS.peek(), temp)
        Draw.push_edge_matrix(temp)
      when "bezier"
        args = file.gets.chomp.split(" ")
        for i in (0...8); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        temp = Matrix.new(4, 0)
        Draw.bezier(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], temp)
        MatrixUtils.multiply($COORDSYS.peek(), temp)
        Draw.push_edge_matrix(temp)
      when "box"
        args = file.gets.chomp.split(" ")
        for i in (0...6); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        temp = Matrix.new(4, 0)
        Draw.box(args[0], args[1], args[2], args[3], args[4], args[5], temp)
        MatrixUtils.multiply($COORDSYS.peek(), temp)
        Draw.push_polygon_matrix(temp)
      when "sphere"
        args = file.gets.chomp.split(" ")
        for i in (0...4); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        temp = Matrix.new(4, 0)
        Draw.sphere(args[0], args[1], args[2], args[3], temp)
        Draw.push_polygon_matrix(MatrixUtils.multiply($COORDSYS.peek(), temp))
      when "torus"
        args = file.gets.chomp.split(" ")
        for i in (0...5); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        temp = Matrix.new(4, 0)
        Draw.torus(args[0], args[1], args[2], args[3], args[4], temp)
        MatrixUtils.multiply($COORDSYS.peek(), temp)
        Draw.push_polygon_matrix(temp)
      when "clear"
        $SCREEN = Screen.new($RESOLUTION)
      when "scale"
        args = file.gets.chomp.split(" ")
        for i in (0...3); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        scale = MatrixUtils.dilation(args[0], args[1], args[2])
        $COORDSYS.modify_top(scale);
      when "move"
        args = file.gets.chomp.split(" ")
        for i in (0...3); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        move = MatrixUtils.translation(args[0], args[1], args[2])
        $COORDSYS.modify_top(move);
      when "rotate"
        args = file.gets.chomp.split(" ")
        puts "With arguments: "  + args.to_s if $DEBUGGING
        rotate = MatrixUtils.rotation(args[0], args[1].to_f)
        $COORDSYS.modify_top(rotate);
      when "pop"
        $COORDSYS.pop()
      when "push"
        $COORDSYS.push()
      when "display"
        display();
      when "save"
        arg = file.gets.chomp
        write_out(file: arg)
      when "quit", "exit"
        exit 0
      else
        puts "ERROR: Unrecognized command \"" + line + '"'
      end
    end
    file.close
  end

end
