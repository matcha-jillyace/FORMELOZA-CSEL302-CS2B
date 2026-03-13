model Classroom

global {

    int nb_students <- 25;
    float world_size <- 100.0;
    bool is_break <- false;

    float avg_attention -> { student mean_of each.attention };
    float avg_performance -> { student mean_of each.performance };
    int high_attention_count -> { student count (each.attention > 0.7) };

    init {
        create student number: nb_students {
            location <- {rnd(world_size), rnd(world_size)};
        }
        // Create one teacher at the center
        create teacher number: 1 {
            location <- {world_size / 2, world_size / 2};
        }
    }

    reflex classroom_cycle {
        if (cycle mod 30 = 0) {
            is_break <- !is_break;
        }
        save [cycle, avg_attention, avg_performance, is_break, high_attention_count]
        to: "classroom_data.csv"
        format: "csv"
        rewrite: (cycle = 0) ? true : false
        header: true;
    }
}

species student {

    float attention <- rnd(1.0);
    float performance <- 0.5;
    float mobility <- rnd(1.0);
    rgb color <- #blue;

    reflex update_attention {
        if (is_break) {
            attention <- min(1.0, attention + 0.05);
        } else {
            attention <- max(0.0, attention - 0.02);
        }
        if (attention > 0.6) {
            performance <- min(1.0, performance + 0.01);
        }
        if (attention > 0.7)      { color <- #green; }
        else if (attention > 0.4) { color <- #yellow; }
        else                      { color <- #red; }
    }

    reflex move {
        float step_size <- mobility * 2;
        float angle <- rnd(360.0);
        location <- location + {step_size * cos(angle), step_size * sin(angle)};
    }

    aspect base {
        draw circle(2) color: color;
    }
}

species teacher {

    // How far the teacher affects students
    float influence_radius <- 20.0;

    // Teacher slowly patrols the room
    reflex patrol {
        float angle <- rnd(360.0);
        location <- location + {cos(angle), sin(angle)};
    }

    // Teacher boosts attention and reduces mobility of nearby students
    reflex influence_students {
        list<student> nearby <- student at_distance influence_radius;
        ask nearby {
            attention <- min(1.0, attention + 0.03); // Boost attention
            mobility <- max(0.1, mobility - 0.01);  // Reduce movement
        }
    }

    aspect base {
        draw circle(3) color: #purple;
        // Show the teacher's influence range as a circle
        draw circle(influence_radius) color: #purple wireframe: true;
    }
}

experiment classroom_simulation type: gui {

    parameter "Initial number of students:" var: nb_students min: 10 max: 100;

    output {
        display main_display type: 2d {
            species student aspect: base;
            species teacher aspect: base;
        }
        monitor "Average Attention"    value: avg_attention;
        monitor "Average Performance"  value: avg_performance;
        monitor "High Attention Count" value: high_attention_count;
    }
}