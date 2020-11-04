require 'json'
require 'time'

class Slot

  def initialize(files_path)
    files_serialized = files_path.map do |file_path|
      file = File.read(file_path)
      serialized = JSON.parse(file)
      serialized
    end
    @busy_slots = busy_slots(files_serialized.flatten)
    @potential_slots = potential_slots(@busy_slots)
  end

  # Obtention des slots disponible en comparant les slots potentiels sur les jours sélectionnés avec les slots déjà bookés
  def get_slots
    available_slots = []
    @potential_slots.each do |slot|
      overlap = @busy_slots.map do |booked| 
        overlaps?(booked, slot)
      end
      !overlap.include?(true) ? available_slots << slot : ''
    end
    available = available_slots.map do |slot|
      hash_slot = {}
      hash_slot[:start] = slot.begin
      hash_slot[:end] = slot.end
      hash_slot
    end
    return available
  end

  private

  # transformation de l'array sérialisé issu du JSON de l'API Google pour obtenir un array de slots sous forme de 'range' de date/time
  # HYPOTHESE N°1 : Les participants sont sur le même fuseau horaire (on suppose ici qu'ils sont sur le fuseau UTC mais ce n'est pas important)
  def busy_slots(input)
    slots_parsed = input.map do |date|
      start_time = Time.parse(date['start'] + 'UTC').to_datetime.to_time
      end_time = Time.parse(date['end'] + 'UTC').to_datetime.to_time
      booked = (start_time..end_time)
      booked
    end
  end

  # création d'un array avec tous les slots horaires existants entre 9h et 18h pour les jours présents dans les fichiers JSON
  # HYPOTHESE N°2 : Les jours sur lesquels on lance la recherche de slots sont tous présents dans les fichiers JSON. Si ce n'est pas le cas, il faut imaginer que la demande inclut des ranges de dates 
  def potential_slots(busy_slots)
    start_date = busy_slots.min_by {|slot| slot.begin}.begin.to_date
    end_date = busy_slots.max_by {|slot| slot.end}.end.to_date
    range = (start_date..end_date).to_a.map do |date|
      slots = []
      n = 9
      9.times do 
        start_time = (date.to_datetime + (n/24.0)).to_time
        end_time = (start_time.to_datetime + (1/24.0)).to_time
        slots << (start_time..end_time)
        n += 1
      end
      slots
    end
    return range.flatten
  end

  # Methode (qui existe sur Rails mais pas en pur Ruby) qui permet de déterminer si un slot (slot_b) est entièrement compris dans un autre (slot_a)
  def overlaps?(slot_a, slot_b)
    slot_b.begin < slot_a.end && slot_a.begin < slot_b.end 
  end 
end

files = ['input_andy.json', 'input_sandra.json']
slots = Slot.new(files)
p slots.get_slots