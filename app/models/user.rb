# frozen_string_literal: true

class User < ApplicationRecord
  has_many :reviews, dependent: :nullify

  VALID_EMAIL_REGEX = /\A[a-z0-9]+[_a-z0-9.-][a-z0-9]+@[a-z0-9-]+(.[a-z0-9-]+)(.[a-z]{2,4})\z/
  VALID_NAME_REGEX = /\A(?=.{2,40}$)[a-zA-ZñÑáéíóúÁÉÍÓÚ]+(\s[a-zA-ZñÑáéíóúÁÉÍÓÚ]+)?\z/
  validates :email, format: { with: VALID_EMAIL_REGEX, message: "es invalido" },
            confirmation: { case_sensitive: false },
            uniqueness: { message: "Ya existe" },
            length: { in: 7..254, message: " El correo debe estar los 7 a 254 caracteres" },
            presence: { message: "no puede estar en blanco" }
  validates :name, presence: { message: "Ingrese el primer nombre " },
            length: { in: 2..40, message: "El nombre debe ser de mínimo largo 3" },
            format: { with: VALID_NAME_REGEX, message: "Se permiten solo letras en los nombres" }
  validates :last_name, presence: { message: "Ingrese el primer apellido" },
            length: { in: 2..20, message: "El apellido debe ser de mínimo largo 3" },
            format: { with: VALID_NAME_REGEX, message: "Se permiten solo letras en los apellidos" }
  validates :second_last_name, presence: { message: "Ingrese el segundo apellido" },
            length: { in: 2..20, message: "El apellido debe ser de mínimo largo 3" },
            format: { with: VALID_NAME_REGEX, message: "Se permiten solo letras en los apellidos" }
  validates :active, inclusion: { in: [ true, false ] }
  validates :banned, inclusion: { in: [ true, false ] }

  after_update :update_book_averages_if_banned_status_changed

  def full_name
    "#{name} #{last_name} #{second_last_name}"
  end

  def ban!
    update!(banned: true)
  end

  def unban!
    update!(banned: false)
  end

  private

  def update_book_averages_if_banned_status_changed
    return unless saved_change_to_banned?

    book_ids = reviews.distinct.pluck(:book_id)
    return if book_ids.empty?

    Book.where(id: book_ids).find_each do |book|
      book.with_lock do
        book.recalculate_average!
      end
    end
  end
end
