// ============================================================
//  BEAT STUDIO  —  8-Bit Chiptune Edition
//  Bypasses broken Windows MIDI drivers using processing.sound
// ============================================================

import processing.sound.*;
import java.util.ArrayList;

// ── Global state ────────────────────────────────────────────
ArrayList<Track> tracks;
int     NUM_STEPS   = 16;
int     BPM         = 128;
int     currentStep = 0;
long    lastStepTime = 0;
boolean playing     = false;

// ── Audio state (8-Bit Synthesizers) ────────────────────────
SinOsc     kickOsc;   Env kickEnv;
WhiteNoise noiseOsc;  Env noiseEnv;
TriOsc     synthOsc;  Env synthEnv;
SqrOsc     bassOsc;   Env bassEnv;

// ── Layout constants ────────────────────────────────────────
int HEADER_H  = 60;
int LABEL_W   = 130;
int CELL_SIZE = 36;
int CELL_GAP  = 3;
int TRACK_H   = 48;
int TRACK_PAD = 5;

// ── Colour palette ──────────────────────────────────────────
color BG          = #1A1A2E;
color PANEL       = #16213E;
color ACCENT      = #E94560;
color ACCENT2     = #0F3460;
color PLAYHEAD    = #FFD700;
color TEXT_LIGHT  = #EAEAEA;
color TEXT_DIM    = #7A7A9A;
color CELL_OFF    = #0D0D1A;
color CELL_ON_DRM = #E94560;
color CELL_ON_MEL = #00C9A7;
color CELL_HOV    = #2A2A4A;

// ============================================================
//  CLASS: Step
// ============================================================
class Step {
  boolean active;
  int     velocity;

  Step() {
    this.active   = false;
    this.velocity = 100;
  }
}

// ============================================================
//  CLASS: Track  (DRUMS - Uses Noise & Low Sine Waves)
// ============================================================
class Track {
  String          name;
  color           activeColor;
  ArrayList<Step> steps;

  Track(String name, color activeColor) {
    this.name        = name;
    this.activeColor = activeColor;
    this.steps       = new ArrayList<Step>();

    for (int i = 0; i < NUM_STEPS; i++) {
      this.steps.add(new Step());
    }
  }

  String label() {
    return name;
  }

  void play() {
    // 8-Bit Drum Synthesis using Envelopes (Attack, Sustain Time, Sustain Level, Release)
    if (name.equals("Kick") || name.equals("Tom")) {
      kickOsc.play();
      kickOsc.freq(name.equals("Kick") ? 55 : 110);
      kickEnv.play(kickOsc, 0.005, 0.02, 1.0, 0.2);
    } 
    else if (name.equals("Snare") || name.equals("Clap")) {
      noiseOsc.play();
      noiseEnv.play(noiseOsc, 0.001, 0.05, 0.8, 0.15);
    } 
    else if (name.equals("Hi-Hat") || name.equals("Closed HH") || name.equals("Shaker")) {
      noiseOsc.play();
      noiseEnv.play(noiseOsc, 0.001, 0.005, 0.4, 0.05);
    } 
    else if (name.equals("Open HH") || name.equals("Crash") || name.equals("Ride")) {
      noiseOsc.play();
      noiseEnv.play(noiseOsc, 0.001, 0.1, 0.6, 0.4);
    }
  }
}

// ============================================================
//  CLASS: MelodicTrack  (SYNTHS - Uses Triangle & Square Waves)
// ============================================================
class MelodicTrack extends Track {
  String rootNote;

  MelodicTrack(String name, String rootNote, color activeColor) {
    super(name, activeColor);
    this.rootNote = rootNote;
  }

  String label() {
    return name + " [" + rootNote + "]";
  }

  void play() {
    // Convert Note String (e.g. "C4") to Frequency
    String[] noteNames = { "C","C#","D","D#","E","F","F#","G","G#","A","A#","B" };
    int octave = Character.getNumericValue(rootNote.charAt(rootNote.length() - 1));
    String notePart = rootNote.substring(0, rootNote.length() - 1);
    
    int idx = 0;
    for (int i = 0; i < noteNames.length; i++) {
      if (noteNames[i].equals(notePart)) { idx = i; break; }
    }
    
    int pitch = idx + (octave + 1) * 12; 
    float freq = pow(2.0, (pitch - 69.0) / 12.0) * 440.0;

    // Route to Square wave for Bass, Triangle wave for Leads/Chords
    if (name.equals("Bass") || name.equals("Sub")) {
      bassOsc.play();
      bassOsc.freq(freq);
      bassEnv.play(bassOsc, 0.01, 0.1, 0.8, 0.2);
    } else {
      synthOsc.play();
      synthOsc.freq(freq);
      synthEnv.play(synthOsc, 0.02, 0.1, 0.6, 0.3);
    }
  }
}

// ============================================================
//  PROCESSING HOOKS
// ============================================================

void setup() {
  size(760, 560);
  smooth(4);
  
  // Initialize the 8-Bit Audio Engine
  kickOsc = new SinOsc(this);    kickEnv = new Env(this);
  noiseOsc = new WhiteNoise(this); noiseEnv = new Env(this);
  synthOsc = new TriOsc(this);   synthEnv = new Env(this);
  bassOsc = new SqrOsc(this);    bassEnv = new Env(this);

  tracks = new ArrayList<Track>();

  // Seed starter tracks
  tracks.add(new Track("Kick",   CELL_ON_DRM));
  tracks.add(new Track("Snare",  CELL_ON_DRM));
  tracks.add(new Track("Hi-Hat", CELL_ON_DRM));
  tracks.add(new MelodicTrack("Bass", "C2", CELL_ON_MEL));
  tracks.add(new MelodicTrack("Lead", "G4", CELL_ON_MEL));

  // Pre-program a basic beat
  tracks.get(0).steps.get(0).active  = true;
  tracks.get(0).steps.get(4).active  = true;
  tracks.get(0).steps.get(8).active  = true;
  tracks.get(0).steps.get(12).active = true;
  tracks.get(1).steps.get(4).active  = true;
  tracks.get(1).steps.get(12).active = true;
  for (int i = 0; i < NUM_STEPS; i += 2) {
    tracks.get(2).steps.get(i).active = true;
  }
}

void draw() {
  background(BG);
  advanceSequencer();
  drawHeader();
  drawTracks();
  drawInstructions();
}

// ── Sequencer clock ──────────────────────────────────────────
void advanceSequencer() {
  if (!playing) return;

  float msPerStep = (60000.0 / BPM) / 4.0;
  if (millis() - lastStepTime >= msPerStep) {
    lastStepTime = millis();
    currentStep  = (currentStep + 1) % NUM_STEPS;
    triggerSoundsForStep(currentStep);
  }
}

void triggerSoundsForStep(int stepIndex) {
  for (Track tr : tracks) {
    if (tr.steps.get(stepIndex).active) {
      tr.play();
    }
  }
}

// ── Header toolbar ───────────────────────────────────────────
void drawHeader() {
  fill(PANEL); noStroke();
  rect(0, 0, width, HEADER_H);

  fill(ACCENT); textSize(22); textAlign(LEFT, CENTER);
  text("BEAT STUDIO", 16, HEADER_H / 2);

  fill(TEXT_DIM); textSize(11); textAlign(LEFT, CENTER);
  text("BPM", 230, HEADER_H / 2 - 9);
  fill(TEXT_LIGHT); textSize(19); textAlign(LEFT, CENTER);
  text(BPM, 230, HEADER_H / 2 + 8);

  boolean hoverPlay = mouseX > 305 && mouseX < 375 && mouseY < HEADER_H;

  fill(playing ? ACCENT : (hoverPlay ? #555580 : ACCENT2));
  stroke(playing ? ACCENT : TEXT_DIM); strokeWeight(1.5);
  rect(305, 12, 70, 36, 6);

  fill(TEXT_LIGHT); noStroke(); textSize(12);
  textAlign(CENTER, CENTER);
  text(playing ? "■  STOP" : "▶  PLAY", 340, 30);

  fill(TEXT_DIM); textSize(11); textAlign(RIGHT, CENTER);
  text(tracks.size() + " tracks", width - 14, HEADER_H / 2);
}

// ── Track rows ───────────────────────────────────────────────
void drawTracks() {
  int yStart = HEADER_H + 18;

  for (int t = 0; t < tracks.size(); t++) {
    Track tr = tracks.get(t);
    int y = yStart + t * (TRACK_H + TRACK_PAD);

    fill(PANEL); noStroke();
    rect(0, y, LABEL_W, TRACK_H, 4);

    boolean isMelodic = (tr instanceof MelodicTrack);
    fill(isMelodic ? CELL_ON_MEL : CELL_ON_DRM);
    noStroke();
    rect(4, y + 4, 5, TRACK_H - 8, 2);

    fill(TEXT_LIGHT); textSize(12); textAlign(LEFT, CENTER);
    text(tr.label(), 16, y + TRACK_H / 2);

    for (int s = 0; s < NUM_STEPS; s++) {
      Step step = tr.steps.get(s);
      int x  = LABEL_W + 8 + s * (CELL_SIZE + CELL_GAP);
      int cy = y + (TRACK_H - CELL_SIZE) / 2;

      boolean isCurrentStep = (s == currentStep && playing);
      boolean hover = mouseX >= x && mouseX < x + CELL_SIZE
                   && mouseY >= cy && mouseY < cy + CELL_SIZE;

      if (step.active) {
        fill(isCurrentStep ? lerpColor(tr.activeColor, PLAYHEAD, 0.4) : tr.activeColor);
      } else {
        fill(isCurrentStep ? lerpColor(CELL_OFF, PLAYHEAD, 0.15) : (hover ? CELL_HOV : CELL_OFF));
      }

      stroke(s % 4 == 0 ? #33335A : #1E1E3A);
      strokeWeight(1);
      rect(x, cy, CELL_SIZE, CELL_SIZE, 4);

      if (s % 4 == 0) {
        fill(TEXT_DIM);
        noStroke(); textSize(8); textAlign(LEFT, TOP);
        text((s / 4) + 1, x + 2, cy + 2);
      }
    }

    if (playing) {
      int px = LABEL_W + 8 + currentStep * (CELL_SIZE + CELL_GAP) + CELL_SIZE / 2;
      stroke(PLAYHEAD); strokeWeight(2);
      line(px, HEADER_H + 10, px, y - 2);
      noStroke();
    }
  }
}

// ── Instructions bar ─────────────────────────────────────────
void drawInstructions() {
  int y = height - 30;
  fill(PANEL); noStroke();
  rect(0, y, width, 30);
  fill(TEXT_DIM); textSize(11); textAlign(LEFT, CENTER);
  text("SPACE play/stop   D add Drum   M add Melodic   ↑↓ BPM   Click cell to toggle   R reset", 12, y + 15);
}

// ── Mouse ────────────────────────────────────────────────────
void mousePressed() {
  if (mouseX > 305 && mouseX < 375 && mouseY < HEADER_H) {
    playing = !playing;
    if (playing) {
      lastStepTime = millis();
      triggerSoundsForStep(currentStep); 
    }
    return;
  }

  int yStart = HEADER_H + 18;
  for (int t = 0; t < tracks.size(); t++) {
    Track tr = tracks.get(t);
    int y  = yStart + t * (TRACK_H + TRACK_PAD);
    int cy = y + (TRACK_H - CELL_SIZE) / 2;

    for (int s = 0; s < NUM_STEPS; s++) {
      int x = LABEL_W + 8 + s * (CELL_SIZE + CELL_GAP);
      if (mouseX >= x && mouseX < x + CELL_SIZE
       && mouseY >= cy && mouseY < cy + CELL_SIZE) {
        tr.steps.get(s).active = !tr.steps.get(s).active;
        return;
      }
    }
  }
}

// ── Keyboard ─────────────────────────────────────────────────
void keyPressed() {
  if (key == ' ') {
    playing = !playing;
    if (playing) {
      lastStepTime = millis();
      triggerSoundsForStep(currentStep); 
    }

  } else if (key == 'd' || key == 'D') {
    String[] names = { "Clap","Tom","Ride","Open HH","Crash","Perc","Shaker" };
    tracks.add(new Track(names[(int)random(names.length)], CELL_ON_DRM));

  } else if (key == 'm' || key == 'M') {
    String[] names = { "Pad","Arp","Stab","Chord","Sub","Pluck","Keys" };
    String[] notes = { "C3","D3","E3","F3","G3","A3","B3","C4","D4","G4","A4" };
    tracks.add(new MelodicTrack(
      names[(int)random(names.length)],
      notes[(int)random(notes.length)],
      CELL_ON_MEL
    ));
    
  } else if (keyCode == UP) {
    BPM = min(BPM + 2, 220);
  } else if (keyCode == DOWN) {
    BPM = max(BPM - 2, 40);
  } else if (key == 'r' || key == 'R') {
    for (Track tr : tracks) {
      for (Step s : tr.steps) s.active = false;
    }
    playing = false;
    currentStep = 0;
  }
}
