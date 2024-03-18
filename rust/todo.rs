use std::{
    env,
    fs::{self, OpenOptions},
    io::Write,
};
fn main() {
    let args: Vec<String> = env::args().collect();
    let argc = args.len();
    let filename = "todo.txt";
    let contents = fs::read_to_string(filename).expect("File didn't read i think");
    if argc == 1 {
        let mut line_num = 0;
        let mut char_num = 0;
        print!("{:>3}: ", line_num);
        for current in contents.chars() {
            print!("{}", current);
            if current == '\n' && char_num != contents.len() - 1 {
                line_num += 1;
                print!("{:>3}: ", line_num)
            }
            char_num += 1;
        }
    } else {
        if args[1] == "-d" {
            // Oh yeah baby
            let pop_index: i32 = args[2].parse().expect("Uh oh!");
            let mut line_num = 0;
            let mut out_str: String = String::from("");
            for current in contents.chars() {
                if line_num != pop_index {
                    out_str.push(current);
                }
                if current == '\n' {
                    line_num += 1;
                }
            }
            let _ = fs::write(filename, out_str.as_bytes());
        } else {
            let mut fptr = OpenOptions::new()
                .write(true)
                .append(true)
                .open(filename)
                .unwrap();

            if let Err(e) = writeln!(fptr, "{}", args[1]) {
                eprintln!("File write didnt work: {}", e);
            }
        }
    }
}
