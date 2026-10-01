defmodule Liquidacion do
  @moduledoc """
   liquidación del pago a los recolectores.

  Todas las funciones de este módulo son puras: no leen datos externos ni
  imprimen nada, solo reciben valores y retornan resultados.

  - autor: juan manuel castaño buitrago,christian david lopera ,samuel mejia guerrero
  - fecha: Octubre del 2026
  """

  # Valor pagado por cada kilo recolectado
  @tarifa_base 1000
  # Kilos que se deben alcanzar en un día para recibir la bonificación
  @bono_kilos 120
  # Valor de la bonificación diaria
  @bono_pago 8000
  # Descuento por cada día trabajado con alimentación
  @desc_alim 12000

  @doc """
  Calcula el valor de un pesaje según los kilos y el porcentaje de verdes.

  El valor base es `kilos * tarifa_base` y se ajusta según los verdes:


  """
  def valor_pesaje(kilos, verdes) do
    base = kilos * @tarifa_base

    cond do
      verdes <= 2 -> base * 1.05
      verdes <= 5 -> base * 1.0
      verdes <= 10 -> base * 0.90
      true -> base * 0.70
    end
  end

  @doc """
  Calcula la bonificación de un día según los kilos recolectados en total.

  """
  def bonificacion_dia(kilos_dia) do
    if kilos_dia >= @bono_kilos, do: @bono_pago, else: 0
  end

  @doc """
  Calcula el descuento por alimentación.

  Si `alimentacion?` es `true`, el descuento es de 12000 por cada día
  trabajado. Si es `false`, no hay descuento y retorna `0`.

  """
  def descuento_alimentacion(dias_trabajados, alimentacion?) do
    if alimentacion?, do: dias_trabajados * @desc_alim, else: 0
  end

  @doc """
  Liquida a un recolector a partir de sus pesajes.

  Recibe el mapa del `recolector` ( `:codigo` y `:alimentacion`)
  y la lista completa de `pesajes_validos`. De esa lista solo se toman los
  pesajes cuyo `:recolector` coincide con el código del recolector.

  Retorna un mapa con las claves:

  - `:recolector`: el mapa del recolector recibido.
  - `:detalle_diario`: lista de mapas, uno por día trabajado, con las claves
    `:dia`, `:kilos`, `:valor` (suma de los pesajes del día) y `:bonificacion`.
  - `:dias_trabajados`: cantidad de días distintos con al menos un pesaje.
  - `:total_kilos`: kilos recolectados en todos los días.
  - `:suma_pesajes`: valor total de los pesajes, sin bonos ni descuentos.
  - `:total_bonos`: suma de las bonificaciones diarias.
  - `:descuento`: descuento total por alimentación.
  - `:neto`: `suma_pesajes + total_bonos - descuento`.

  Si el recolector no tiene pesajes, todos los totales quedan en `0`.
  """
  def liquidar_recolector(recolector, pesajes_validos) do
    # Filtramos los pesajes que pertenecen únicamente a este recolector
    pesajes_del_recolector =
      Enum.filter(pesajes_validos, fn p -> p.recolector == recolector.codigo end)

    # Agrupamos por día
    pesajes_por_dia = Enum.group_by(pesajes_del_recolector, fn p -> p.dia end)
    dias_trabajados = map_size(pesajes_por_dia)

    # Convertimos el mapa agrupado en una lista de resultados diarios
    detalle_diario =
      Enum.map(pesajes_por_dia, fn {dia, lista_pesajes} ->
        kilos_dia = Enum.reduce(lista_pesajes, 0, fn p, acc -> acc + p.kilos end)

        valor_pesajes_dia =
          Enum.reduce(lista_pesajes, 0, fn p, acc -> acc + valor_pesaje(p.kilos, p.verdes) end)

        bono_dia = bonificacion_dia(kilos_dia)

        %{dia: dia, kilos: kilos_dia, valor: valor_pesajes_dia, bonificacion: bono_dia}
      end)

    total_kilos = Enum.reduce(detalle_diario, 0, fn d, acc -> acc + d.kilos end)
    suma_pesajes = Enum.reduce(detalle_diario, 0, fn d, acc -> acc + d.valor end)
    total_bonos = Enum.reduce(detalle_diario, 0, fn d, acc -> acc + d.bonificacion end)
    descuento = descuento_alimentacion(dias_trabajados, recolector.alimentacion)

    neto = suma_pesajes + total_bonos - descuento

    %{
      recolector: recolector,
      detalle_diario: detalle_diario,
      dias_trabajados: dias_trabajados,
      total_kilos: total_kilos,
      suma_pesajes: suma_pesajes,
      total_bonos: total_bonos,
      descuento: descuento,
      neto: neto
    }
  end

  @doc """
  Liquida a todos los recolectores de la lista.

  Aplica `liquidar_recolector/2` a cada recolector con la misma lista de
  `pesajes_validos` y retorna una lista de liquidaciones, en el mismo orden
  de los recolectores recibidos.
  """
  def liquidar_todos(recolectores, pesajes_validos) do
    Enum.map(recolectores, fn rec -> liquidar_recolector(rec, pesajes_validos) end)
  end
end
