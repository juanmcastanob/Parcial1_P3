defmodule Datos do
  @moduledoc """
  Módulo que tiene los datos de prueba del proyecto de recolección.

  Expone tres colecciones :

  - `recolectores/0`: personas que recogen el producto.
  - `lotes/0`: terrenos donde se realiza la recolección.
  - `pesajes/0`: registros de lo recolectado por cada persona en cada lote y día.

  Los pesajes se relacionan con las otras dos colecciones así:

  - `recolector` corresponde al `codigo` de un recolector.
  - `lote` corresponde al `id` de un lote.



  - autor: juan manuel castaño buitrago,christian david lopera ,samuel mejia guerrero
  - fecha: Octubre del 2026
  """

  @doc """
  Retorna la lista de recolectores registrados.

  Cada recolector contiene:

  - `:codigo`: identificador único .
  - `:nombre`: nombre completo de la persona.
  - `:alimentacion`: `true` si al recolector se le brinda alimentación,
    `false` en caso contrario.


  """
  def recolectores do
    [
      %{codigo: "R01", nombre: "Luz Marina Ospina", alimentacion: true},
      %{codigo: "R02", nombre: "Jhon Fredy Castaño", alimentacion: false},
      %{codigo: "R03", nombre: "Dora Cardona", alimentacion: true},
      %{codigo: "R04", nombre: "Wilson Arango", alimentacion: false}
    ]
  end

  @doc """
  Retorna la lista de lotes disponibles.

  Cada lote contiene:

  - `:id`: identificador único (por ejemplo, `"L1"`).
  - `:nombre`: nombre del lote.
  - `:hectareas`: extensión del lote en hectáreas (número decimal).


  """
  def lotes do
    [
      %{id: "L1", nombre: "El Mirador", hectareas: 2.5},
      %{id: "L2", nombre: "La Cañada", hectareas: 1.5},
      %{id: "L3", nombre: "Buenavista", hectareas: 3.0}
    ]
  end

  @doc """
  Retorna la lista de pesajes registrados

  Cada pesaje  contiene::

  - `:recolector`: código del recolector que realizó el pesaje.
  - `:lote`: id del lote donde se recolectó.
  - `:dia`: número del día de la jornada en que se registró el pesaje.
  - `:kilos`: kilos recolectados (entero o decimal).
  - `:verdes`: cantidad de producto verde (inmaduro) reportada en el pesaje.


"""
  def pesajes do
    [
      %{recolector: "R01", lote: "L1", dia: 1, kilos: 70, verdes: 1.5},
      %{recolector: "R01", lote: "L2", dia: 1, kilos: 55, verdes: 6},
      %{recolector: "R01", lote: "L1", dia: 2, kilos: 90, verdes: 12},
      %{recolector: "R02", lote: "L1", dia: 1, kilos: 100, verdes: 2},
      %{recolector: "R02", lote: "L3", dia: 1, kilos: 45, verdes: 3},
      %{recolector: "R02", lote: "L2", dia: 2, kilos: 60.5, verdes: 4},
      %{recolector: "R02", lote: "L3", dia: 2, kilos: 65, verdes: 5},
      %{recolector: "R02", lote: "L3", dia: 3, kilos: 110, verdes: 1},
      %{recolector: "R03", lote: "L2", dia: 1, kilos: 80, verdes: 3},
      %{recolector: "R03", lote: "L3", dia: 1, kilos: 60, verdes: 4},
      %{recolector: "R03", lote: "L1", dia: 2, kilos: 85, verdes: 2.5},
      %{recolector: "R03", lote: "L2", dia: 3, kilos: 95, verdes: 8},
      %{recolector: "R03", lote: "L1", dia: 3, kilos: 40, verdes: 0},
      # Inconsistente: el recolector "R09" no existe en recolectores/0
      %{recolector: "R09", lote: "L1", dia: 1, kilos: 80, verdes: 3},
      # Inconsistente: el lote "L7" no existe en lotes/0
      %{recolector: "R03", lote: "L7", dia: 2, kilos: 50, verdes: 2},
      # Atípico: día 6 y 300 kilos, muy por encima del resto de registros
      %{recolector: "R04", lote: "L3", dia: 6, kilos: 300, verdes: 3},
      # Inconsistente: pesaje con 0 kilos
      %{recolector: "R02", lote: "L2", dia: 3, kilos: 0, verdes: 4},
      # Atípico: 300 kilos en un solo pesaje
      %{recolector: "R01", lote: "L3", dia: 3, kilos: 300, verdes: 2},
      # Inconsistente: verdes (130) es mayor que los kilos totales (40)
      %{recolector: "R01", lote: "L2", dia: 3, kilos: 40, verdes: 130}
    ]
  end
end
